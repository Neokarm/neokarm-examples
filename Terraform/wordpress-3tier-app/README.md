# Terraform WordPress deployment
## This example works with aws provider version v2.13.0!
## Description:
This TF script will deploy a single region highly available WordPress site with RDS, EC2 and VPC into zCompute. 

## Before you begin: Create SSH Key-Pairs

ssh-keygen -f <path to key file> -t rsa -b 2048
Two files will be created:
 - no suffix file - the private key
 - .pub suffix - the public key. This is the file you pass in tfvars
 
## Before running
Along with your API credentials, ensure you specify the AMI ID in your .tfvars file. A sample has been created to reference. Please use a cloud-ready Ubuntu Xenial image. For list of official AMI's see: https://cloud-images.ubuntu.com/locator/ec2/.

### Networks to be provisioned:
- 1 VPC 
- 1 Database subnet 
- 1 Internal subnet for webservers
- 1 Public subnet for load-balancer

### Resources:
- 1 NLB
- 2 web servers (or more) (Ubuntu Xenial)
- 1 RDS instance (MySQL 5.7)

### Zadara zCompute Requirements:
- Load balancing enabled and initialized from the UI
- Ubuntu Xenial cloud-ready image uploaded and set as Public 
- RDS Enabled with Mysql 5.7 engine initialized
- VPC mode enabled for tenant project

### Tested with: Terraform v0.12 & 0.13

