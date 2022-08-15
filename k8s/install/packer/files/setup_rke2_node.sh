#!/bin/bash

# prepere files for installation
curl -L https://get.rke2.io -o /tmp/install-rke2.sh
chmod +x /tmp/install-rke2.sh
mkdir -p /var/lib/rancher/rke2/agent/images/

# install RKE2 server and agent
INSTALL_RKE2_TYPE=server /tmp/install-rke2.sh
INSTALL_RKE2_TYPE=agent /tmp/install-rke2.sh