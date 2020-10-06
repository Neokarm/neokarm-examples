
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

resource "aws_default_vpc" "default" {

  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default" {
  availability_zone = "symphony"

  tags = {
    Name = "Default subnet"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_default_vpc.default.id

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

data "aws_ami" "ami_image" {
  filter {
    name   = "name"
    values = [var.image_name]
  }

  owners = ["self"]
}

resource "aws_instance" "instance" {
  count = 5

  ami                    = data.aws_ami.ami_image.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name      = "Sample instance",
    CreatedBy = "Terraform"
  }
}

resource "aws_eip" "eip" {
  count = 5

  instance = element(aws_instance.instance.*.id, count.index)
  vpc      = true
}
