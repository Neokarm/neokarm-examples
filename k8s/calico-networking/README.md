# Calico Networking
This README refers to the internal Kubernetes network options that rke2 supports(CNIs)
## Choosing a CNI
rke2 server takes a parameter that refers to the cni to install.
The current supported options:
```
https://docs.rke2.io/install/network_options/
```
Default in this installation: ```calico``` will patch 
Default in rke2 would be ```canal```.



In order to change this theres a parameter in ```variables.tf``` called  ```cni```.

## Changing network encapsulation to bgp
- change ```bgp``` parameter in ```variables.tf``` to true.
A job will be created by rke to patch the requested change and this will attempt to rolling restart the daemonset of calico-node pods.
> Important: Verify that all of the calico-node pods are restarting, help if required.
- Install calicoctl in order to interact with calico
```https://projectcalico.docs.tigera.io/maintenance/clis/calicoctl/install```
```
curl -L https://github.com/projectcalico/calico/releases/download/<calicoctl version>/calicoctl-linux-amd64 -o calicoctl
```
Example version ```v3.22.0``` will work with the ```--allow-version-mismatch``` flag.
```
chmod +x ./calicoctl
```
This uses the applied ```KUBECONFIG``` env variable to connect.

- Apply ```bgpconfiguration.yaml``` to configure the nodes to work with the default ASnumber and node to node mesh.
```
calicoctl apply -f bgpconfiguration.yaml
```
> Important: Verify that all of the calico-node pods are restarting.
- Check if rke succeded in changing the IPPool in calico
```
calicoctl get ippool -oyaml
```
The IPPool should have
```
  ipipMode: Never
  natOutgoing: true
  nodeSelector: all()
  vxlanMode: Never
```
If this is not the case we will edit the IPPool with kubectl and correct the parameters
```
kubectl edit ippool <ippoolname>
```
> Important: Verify that all of the calico-node pods are restarting.
- Calico is now properly configured to bgp!