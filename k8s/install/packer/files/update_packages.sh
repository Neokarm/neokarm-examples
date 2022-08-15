#!/bin/bash

# Install RPM
yum update -y
yum -y install strace pciutils unbound-libs httpd-tools python3 audit-libs-python bash-completion libseccomp libsemanage-python policycoreutils-python python-IPy setools-libs tcpdump bind-utils
pip3 install -U pip
pip3 install requests boto3 pyudev retrying
