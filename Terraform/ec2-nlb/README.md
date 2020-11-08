### nlb example

## Description:
This TF script will deploy a Network Load balancer between web servers  with ELB, EC2 and VPC into Neokarm Symphony.

## Before you begin: Create SSH Key-Pairs

ssh-keygen -f <path to key file> -t rsa -b 2048
Two files will be created:
 - without suffix file - the private key
 - .pub suffix - the public key. This is the file you pass in tfvars

## Before running
Along with your API credentials, ensure you specify the AMI ID in your .tfvars file. A sample has been created to reference. Please use a cloud-ready Ubuntu Xenial image. For list of official AMI's see: https://cloud-images.ubuntu.com/locator/ec2/.

### Networks to be provisioned:
- 1 VPC
- 1 private subnet
- 1 public subnet

### Resources:
- 1 NLB
- 3 web servers (or more) (Ubuntu Xenial)


### Neokarm Symphony Requirements:
- Load balancing enabled and initialized from the UI
- Ubuntu Xenial cloud-ready image uploaded and set as Public

### Tested with: Terraform v0.12 & v0.13

