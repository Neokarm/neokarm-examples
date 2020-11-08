# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * Public subnets
#          * Private subnet
#          * DHCP options
#          * Internet gateway
#          * Routing table
#          * 3 Instances
#          * 2 Security groups
#          * Network load balancer
#          * Target group
#          * Listener
#
#     This example was tested on versions:
#     - Symphony version 5.5.3
#     - terraform 0.12.27 & 0.13
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "Sample VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.vpc.id

  tags = {
    Name      = "Sample public subnet",
    CreatedBy = "Terraform"
  }
}

resource "aws_subnet" "private_subnet" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.vpc.id

  tags = {
    Name      = "Sample private subnet",
    CreatedBy = "Terraform"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]

  tags = {
    Name      = "Sample DNS resolvers",
    CreatedBy = "Terraform"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "Sample public route table",
    CreatedBy = "Terraform"
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_instance" "nginx" {
  count = var.quantity

  ami                    = var.ami_image
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.nginx.id]

  user_data = <<-EOF
                #! /bin/bash
    sudo yum update -y
                sudo yum install -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
    sudo docker run -p 80:80 -d nginx
  EOF


  tags = {
    Name      = "Sample Nginx",
    CreatedBy = "Terraform"
  }
}

resource "aws_security_group" "nginx" {
  name   = "instance-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg" {
  name   = "nlb-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "nlb" {
  name               = "sample-nlb"
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]
  security_groups    = [aws_security_group.sg.id]
  depends_on         = [aws_route_table.rt]
  tags = {
    Name      = "sample-load-balancer",
    CreatedBy = "Terraform"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.lb-tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "lb-tg" {
  name        = "tf-example-lb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
  stickiness {
    enabled = false
    type = "lb_cookie"
  }
}
resource "aws_lb_target_group_attachment" "lb_tg_attach" {
  target_group_arn = aws_lb_target_group.lb-tg.arn
  count = 3
  target_id        = aws_instance.nginx[count.index].id
  port             = 80
}

