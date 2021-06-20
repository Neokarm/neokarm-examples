# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * Subnet
#          * DHCP options
#          * Internet gateway
#          * Routing table
#          * 3 Instances
#          * Security group
#          * 3 elastic ip
#  
#     This example was tested on versions:
#     - zCompute version 5.5.3
#     - terraform 0.12.27 & 0.13
# ---------------------------------------------------------------------------------------------------------------------
# Creating a VPC & Networking
resource "aws_vpc" "my_vpc" {
  cidr_block         = "192.168.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "Demo VPC"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.my_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}
resource "aws_subnet" "my_subnet" {
  cidr_block = "192.168.10.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  tags = {
    Name = "Demo subnet"
  }

  # Makes sure DHCP configuration is absorbed in the subnet - zCompute specific
  depends_on = ["aws_vpc_dhcp_options_association.dns_resolver"]
}

resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.my_vpc.id
}

# The default route table will allow each subnet to route to the Internet Gateway
resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }
}


############ Instance Creation #############################

# Creating an instance
resource "aws_instance" "my_instance" {
  ami                    = var.ami_image
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_all_sg.id]
  count                  = var.instance_number
  tags = {
    Name = "my_instance_${count.index}"
  }
}

resource "aws_eip" "my_instance_eip" {
  count      = var.instance_number
  depends_on = ["aws_internet_gateway.my_gw"]
}

resource "aws_eip_association" "my_eip_assoc" {
  count         = var.instance_number
  instance_id   = "${element(aws_instance.my_instance.*.id, count.index)}"
  allocation_id = "${element(aws_eip.my_instance_eip.*.id, count.index)}"
}


################## Security Group ##################

resource "aws_security_group" "allow_all_sg" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol    = "udp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8 #ICMP type number if protocol is "icmp"
    to_port     = 0 #ICMP code number if protocol is "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
