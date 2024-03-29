#!/bin/bash

# Install RPM
yum update -y
yum -y install pciutils unbound-libs httpd-tools python3 audit-libs-python bash-completion libseccomp libsemanage-python policycoreutils-python python-IPy setools-libs tcpdump bind-utils
pip3 install -U pip
pip3 install requests boto3 pyudev retrying

# prepere files for installation
curl -L https://get.rke2.io -o /tmp/install-rke2.sh
chmod +x /tmp/install-rke2.sh
mkdir -p /var/lib/rancher/rke2/agent/images/

# install RKE2 server and agent
INSTALL_RKE2_TYPE=server /tmp/install-rke2.sh
INSTALL_RKE2_TYPE=agent /tmp/install-rke2.sh