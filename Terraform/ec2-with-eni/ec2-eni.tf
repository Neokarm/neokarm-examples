# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * 2 Subnets
#          * 1 Instance
#          * 2 Network interface
#  
#     This example was tested on versions:
#     - zCompute version 5.5.3
#     - terraform 0.12.27 & 0.13
# ---------------------------------------------------------------------------------------------------------------------


resource "aws_vpc" "test_vpc" {
  cidr_block           = "172.127.0.0/16"
  enable_dns_hostnames = false
  enable_dns_support   = false
}

resource "aws_subnet" "test-network1" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "172.127.1.0/24"
}

resource "aws_subnet" "test-network2" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "172.127.2.0/24"
}

resource "aws_instance" "ec2_instance" {
  ami           = var.aws_ami
  instance_type = "t2.micro"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni-1.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni-2.id
  }
}

resource "aws_network_interface" "eni-1" {
  subnet_id = aws_subnet.test-network1.id
}

resource "aws_network_interface" "eni-2" {
  subnet_id = aws_subnet.test-network2.id
}
