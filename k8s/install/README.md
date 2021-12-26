# Installing Kubernetes on zCompute

1. [Prerequisites](#prerequisites)
2. [Terraform](#terraform-installation) / [Manual](#manual-installation) Installation
3. [Post Installation](#post-installation)

## Prerequisites

### zCompute Access Key

Please create access keys and make them available to the terraform script according to: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication

### Terraform

In order to deploy K8S using the provided scripts you will need the terraform binary (Can be downloaded from: https://www.terraform.io/downloads). The script was tested with version 0.14.9 and Terraform AWS provider version 3.70.0

### CentOS Image:

Make sure that a CentOS 7.8 Cloud image is available for deploying the kubernetes VM nodes in zCompute.

### Cluster Certificate:

Using the EBS driver require a valid certificate chain, trusted by the EBS driver deployment.
In case the the cluster is using a certificate signed by a private or unknown CA you will need to inject its CA certificate into the EBS driver pod.
this procedure is described in [Certificate install](#cluster-certificate-installation)

### SSH private key

The Terraform script uses SSH in order to access the K8S nodes during installation.
If you want to use a new SSH key create it using:

```sh
ssh-keygen -b 4096 -t rsa <key-file>
```

This will create a private ssh key in <key-file> and a public ssh key in <key-file>.pub
You will need to provide these files to the terraform script.

### NAT Gateway Engine (Terraform only):

The terraform script creates NAT Gateway to allow egress internet access to kubernetes nodes residing inside a private network.
As an admin go to Service Engines -> Networking and enable the `VPC_NATGW` engine.

## Cluster Certificate Installation

Using the EBS driver require a valid certificate chain, trusted by the EBS driver pod.
In case the the cluster is using a certificate signed by a private or unknown CA you will need to inject its CA certificate into the EBS driver pod.

Ensure the following files are located in the certificates folder:

- ca.crt
- cluster.crt

## Terraform Installation

The provided terraform scripts are provided as an example only.

The scripts will create a K8S cluster based on RKE2 https://docs.rke2.io/ in zCompute.
The K8S cluster will be created on a private subnet on a dedicated VPC, and will be given egress internet access via a NAT Gateway on a public subnet.
In addtion the script will also setup on a public subnet:

- Load Balancer for `kubelet` API, that will use the Kubernetes master nodes as targets.
- Bastion VM that allows SSH access the the Kubernetes nodes.

In each node a script that is used to convert zCompute disk devices name to an AWS compatible names is installed as a udev drop-in script.
The script template and a corresponding udev rule are located in `extra/disk-mapper/`

In order to access the zCompute API the created nodes are assigned an instance profile.

> For sake of simplicity the instance profile is have full user permissions.

### Running the installation

1. Copy or rename `terraform.tfvars.template` to `terraform.tfvars` and provide all required variables inside it, make sure their value matches the ceritficate created above and the CentOS image selected.
   The following parameters should be provided:

   - `ssh_public_key_file` - This SSH public key will be installed on the K8S nodes
   - `ssh_private_key_file` - This SSH private key will be used by the provisioning script to login in to the K8S nodes. It is not copied or moved
   - `zcompute_api_ip` - IP address or hostname of the zCompute API
   - `ami_id` - AMI ID Of a valid and accessible CentOS 7.8 Cloud image in zCompute

   There are other parameters that can be modified, please consult with their description in `variables.tf` file.

2. Run `terraform init`
3. Run `terraform apply`

   note: _The `terraform apply` command may fail on the last stage due to timeout, but as long as all K8S nodes reach ready state this is fine_

4. Currently, creating the load balancer listener isn't possible due to ARN validation failures done by terraform's AWS provider.
   This will be fixed in future versions, but for now, manual intervention is required:

   - Go to `Load Balancers` and selected the LB created by the terraform - by default it will be called `rke-masters-lb`.
   - Inside the bottom Listeners table, click on Create.
   - Input the kubernetes API port - `6443`.
   - Select the kubernetes masters target group - by default it will be called `rke-masters-tg`.
   - Submit :)

5. A kubeconfig.yaml and ca-certificates.crt will be generated, to communicate with the k8s cluster.
6. Run `KUBECONFIG=kubeconfig.yaml kubectl get nodes` until you see:

   ```shell
   NAME                       STATUS   ROLES                       AGE     VERSION
   rke2-agent-1.zadara.net    Ready    <none>                      5m53s   v1.21.5+rke2r1
   rke2-agent-2.zadara.net    Ready    <none>                      5m53s   v1.21.5+rke2r1
   rke2-agent-3.zadara.net    Ready    <none>                      5m57s   v1.21.5+rke2r1
   rke2-server-1.zadara.net   Ready    control-plane,etcd,master   8m25s   v1.21.5+rke2r1
   rke2-server-2.zadara.net   Ready    control-plane,etcd,master   2m44s   v1.21.5+rke2r1
   rke2-server-3.zadara.net   Ready    control-plane,etcd,master   104s    v1.21.5+rke2r1
   ```

## Manual Installation

1. Create instances, and install kubernetes on them as you would do on any other cloud/bare-metal machine.

- If you plan to leverage zCompute's AWS API for cloud-provider integration make sure to provide this parameter to kubelet: `provider-id=ec2://symphony/${instance-id-in-aws-format}`.

2. If you used a self-singed certificate as the cluster certificate, make sure to install the CA certificate on the instances CA store.
3. Download the CA certificate bundle from one of the kubernetes nodes:

```sh
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_private_key_file} centos@${kubernetes-node-public-ip}:/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ca-certificates.crt
```

## Post Installation

Create a config map from the CA certificate bundle obtained from the terraform/step #3 under manual installation:

```sh
kubectl -n kube-system create configmap --from-file=ca-certificates.crt symphony-ca-certificates-bundle
```
