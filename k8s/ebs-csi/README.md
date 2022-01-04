# [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)

zCompute's AWS API can be leveraged to be used with AWS EBS CSI driver to provision and attach EBS volumes to concile with Kubernetes PVCs.

## Support matrix with zCompute:

|       Feature        |     Supported      |
| :------------------: | :----------------: |
| Static Provisioning  |         ✅         |
| Dynamic Provisioning |         ✅         |
|     Block Volume     |         ✅         |
|   Volume Resizing    | ❌ (✅ on v22.02+) |
|   Volume Snapshot    |   🟡 (Untested)    |
|         NVMe         |   🟡 (Untested)    |
|    Mount Options     |   🟡 (Untested)    |

## Usage

### 1. download the helm chart locally:

```sh
helm pull aws-ebs-csi-driver/aws-ebs-csi-driver --untar --version=2.6.1
```

### 2. Add the ca-certificates bundle config map as a mount on the EBS plugin container:

The following patch is relevant for version 2.6.1 of the EBS CSI driver, but can be used to deduce the changes required for other versions:

```patch
--- aws-ebs-csi-driver/templates/controller.yaml
+++ aws-ebs-csi-driver/templates/controller.yaml
@@ -154,6 +154,7 @@
             {{- end}}
             - --leader-election=true
             - --default-fstype={{ .Values.controller.defaultFsType }}
+            - --timeout=180s
           env:
             - name: ADDRESS
               value: /var/lib/csi/sockets/pluginproxy/csi.sock
```

To apply it:

```sh
patch -p 0 < provisioner-timeout.patch
```

### 3. Optional: Use custom ca-certificates bundle

In case that the cluster is using a custom or unknown CA, it is required to update the CA certificates bundle in the EBS driver.
This is done by mounting the CA certificate bundle from a config map.
The following patch is relevant for version 2.6.1 of the EBS CSI driver, but can be used to deduce the changes required for other versions:

```patch
--- aws-ebs-csi-driver/templates/controller.yaml
+++ aws-ebs-csi-driver/templates/controller.yaml
@@ -118,6 +118,8 @@
           volumeMounts:
             - name: socket-dir
               mountPath: /var/lib/csi/sockets/pluginproxy/
+            - name: ca-certificate-bundle
+              mountPath: /etc/ssl/certs
           ports:
             - name: healthz
               containerPort: 9808
@@ -261,3 +263,9 @@
       volumes:
         - name: socket-dir
           emptyDir: {}
+        - name: ca-certificate-bundle
+          configMap:
+            name: zcompute-ca-certificates-bundle
+            items:
+              - key: ca-certificates.crt
+                path: ca-certificates.crt
```

To apply it:

```sh
patch -p 0 < controller-ca-bundle.patch
```

create the ca-certificate config map

```sh
kubectl -n kube-system create configmap --from-file=ca-certificates.crt zcompute-ca-certificates-bundle
```

Make sure that after you apply the helm chard patches there are no \*.orig file in the template directory.
If there are, delete them

### 5. Install the modified helm chart with the additional changed values:

Change the zcompute-host name to the actual API dns

```yaml
# aws-ebs-csi-driver/values.yaml
controller:
  env:
    - name: AWS_EC2_ENDPOINT
      value: 'https://${zcompute-hostname}/api/v2/aws/ec2'
storageClasses:
  - name: 'aws-sc'
    annotations:
      storageclass.kubernetes.io/is-default-class: 'true'
```

```sh
helm -n kube-system -f aws-ebs-csi-driver/values.yaml install aws-ebs-csi-driver aws-ebs-csi-driver/
```