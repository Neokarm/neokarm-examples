# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * Public Subnet
#          * DHCP options
#          * Internet gateway
#          * Routing table
#          * 2 Instances
#          * 2 Security groups
#          * bastion instance
#          * 2 Key pair
#          * Eip 
#  
#     This example was tested on versions:
#     - zCompute version 5.5.3
#     - terraform 0.12.27 & 0.13
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  ami       = var.bastion_ami_image
  subnet_id = aws_subnet.pub_subnet.id

  tags = {
    Name = "bastion_instance"
  }

  # Can use any aws instance type supported by zCompute
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    aws_security_group.ssh-sg.id,
    aws_security_group.sg-any.id,
    aws_security_group.icmp-sg.id,
  ]
  key_name = aws_key_pair.bastion_keypair.key_name
}

resource "aws_key_pair" "bastion_keypair" {
  public_key = file(pathexpand(var.public_bastion_keypair_path))
  key_name   = "bastion_kp"
}

resource "aws_eip" "bastion-eip" {
  vpc = true
}

resource "aws_eip_association" "bastion_eip_association" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion-eip.id
}

output "bastion_elastic_ips" {
  value = aws_eip.bastion-eip.public_ip
}

####################### General ###################################

resource "aws_security_group" "ssh-sg" {
  name   = "bastion_ingress-ssh"
  vpc_id = aws_vpc.app_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "icmp-sg" {
  name   = "bastion_ingress-ping"
  vpc_id = aws_vpc.app_vpc.id
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-any" {
  name   = "bastion_egress-all"
  vpc_id = aws_vpc.app_vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "app_keypair" {
  public_key = file(pathexpand(var.public_keypair_path))
  key_name   = "packer_kp"
}

