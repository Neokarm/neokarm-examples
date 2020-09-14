
# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * Subnet
#          * DHCP options
#          * Internet gateway
#          * Routing table route in default routing table
#          * Security group
#          * Instance
#          * Elastic IP
#  
#     This example was tested on versions:
#     - Symphony version 5.5.3
#     - terraform 0.12.27
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block         = "192.168.0.0/16"
  enable_dns_support = false

  tags = {
    Name      = "Sample VPC",
    CreatedBy = "Terraform"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

resource "aws_subnet" "subnet" {
  cidr_block = "192.168.10.0/24"
  vpc_id     = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "Sample Subnet",
    CreatedBy = "Terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance" {
  ami                    = var.ami_image
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

  tags = {
    Name      = "Sample instance",
    CreatedBy = "Terraform"
  }
}

resource "aws_eip" "eip" {
  instance = "${aws_instance.instance.id}"
  vpc      = true
}