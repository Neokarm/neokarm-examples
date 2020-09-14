
# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * 2 Subnets
#          * DHCP options
#          * Internet gateway
#          * Routing table
#          * 3 Instances
#          * 2 Security groups
#          * Application load balancer
#          * Target group
#          * Listener
#  
#     This example was tested on versions:
#     - Symphony version 5.5.3
#     - terraform 0.12.27
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
    Name = "Sample public subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.vpc.id

  tags = {
    Name = "Sample private subnet"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]

  tags = {
    Name = "Sample DNS resolvers"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Smaple public RoutTable"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Creating two instances of web server ami with cloudinit
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
    Name = "Sample Nginx"
  }
}

resource "aws_security_group" "nginx" {
  name   = "instance-sg"
  vpc_id = aws_vpc.vpc.id

  # Internal HTTP access from anywhere
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb" {
  name   = "elb-sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
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

resource "aws_alb" "alb" {
  name               = "sample-elb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet.id]
  security_groups    = [aws_security_group.elb.id]

  tags = {
    Name = "smaple-load-balancer"
  }
}

resource "aws_alb_target_group" "instances" {
  name     = "samaple-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_alb_target_group_attachment" "attach_web_servers" {
  target_group_arn = aws_alb_target_group.instances.arn
  target_id        = element(aws_instance.nginx.*.id, count.index)
  port             = 80
  count            = var.quantity
}

resource "aws_alb_listener" "list" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    target_group_arn = aws_alb_target_group.instances.arn
    type             = "forward"
  }
}
