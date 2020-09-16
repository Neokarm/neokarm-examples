
# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * Security group
#          * Key pair
#          * Instance (Packer host)
#          * Elastic IP
#          * null_resource (Remote execute to the Packer host)
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
  name        = "packer_allow_all"
  description = "Allow ALL traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "Allow ALL traffic"
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

  tags = {
    Name = "packer-allow-all"
  }
}

data "aws_ami" "image" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

resource "aws_key_pair" "packer" {
  key_name_prefix   = "packer-example"
  public_key = file("${path.module}/${var.public_key}")
}


resource "aws_instance" "packer_instance" {
  subnet_id              = aws_default_subnet.default.id
  ami                    = data.aws_ami.image.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.packer.key_name
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "Packer instance"
  }
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.packer_instance.id
  allocation_id = aws_eip.eip.id
}

resource "null_resource" "ssh_connection" {

  connection {
    host        = aws_eip.eip.private_ip
    type        = "ssh"
    private_key = file("${path.module}/${var.private_key}")
    port        = 22
    user        = var.ssh_username
    agent       = false
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "packer.json"
    destination = "/tmp/packer.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y yum-utils",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo",
      "sudo yum install -y packer",
      "packer build -var 'symphony_ip=${var.symphony_ip}' -var 'aws_access_key=${var.aws_access_key}' -var 'aws_secret_key=${var.aws_secret_key}' -var 'vpc_id=${aws_default_vpc.default.id}' -var 'subnet_id=${aws_default_subnet.default.id}' -var 'ami_name=${var.ami_name}' -var 'ssh_username=${var.ssh_username}' -var 'instance_type=${var.instance_type}' /tmp/packer.json",
    ]
  }

  depends_on = [aws_eip_association.eip_assoc]
}
