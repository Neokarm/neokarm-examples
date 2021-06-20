



# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * 2 Subnets
#          * DHCP options
#          * Internet gateway
#          * Routing table
#          * bastion instance
#          * bastion eip
#          * key pair
#          * 3 Security groups
#          * Application load balancer
#          * Target group
#          * Listener
#          * Auto Scaling Group
#          * Launch Configuration
#  
#     This example was tested on versions:
#     - zCompute version 5.5.3
#     - terraform 0.12 & 0.13
# ---------------------------------------------------------------------------------------------------------------------
###################################
# Creating a VPC & Networking
###################################

resource "aws_vpc" "bg-vpc" {
  cidr_block         = "172.21.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "Blue-Green Example VPC"
  }
}

resource "aws_subnet" "instances_subnet" {
  cidr_block = "172.21.1.0/24"
  vpc_id     = aws_vpc.bg-vpc.id

  tags = {
    Name = "Blue-Green Example web subnet"
  }
}

# add dhcp options
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}

# associate dhcp with vpc
resource "aws_vpc_dhcp_options_association" "associate_dns_resolver" {
  vpc_id          = aws_vpc.bg-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

# create igw
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.bg-vpc.id
}

#new default route table with igw association 
resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.bg-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
}

###################################
# Cloud init data
data "template_file" "webconfig" {
  template = file("./webconfig.cfg")
}

data "template_cloudinit_config" "web_config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "webconfig.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.webconfig.rendered
  }
}

###################################

resource "aws_launch_configuration" "asg_launch_configuration" {
  name_prefix   = "bg_lc_"
  image_id      = var.ami_webserver
  instance_type = var.web_servers_type
  key_name      = aws_key_pair.app_keypair.key_name

  security_groups = [
    aws_security_group.webservers_sg.id,
    aws_security_group.allout_sg.id,
  ]
  user_data = data.template_cloudinit_config.web_config.rendered
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bg_asg" {
  name                 = "asg_${aws_launch_configuration.asg_launch_configuration.name}"
  max_size             = 3
  min_size             = 2
  min_elb_capacity     = 2
  launch_configuration = aws_launch_configuration.asg_launch_configuration.id
  health_check_type    = "EC2"
  termination_policies = ["OldestLaunchConfiguration"]
  vpc_zone_identifier  = [aws_subnet.instances_subnet.id]

  lifecycle {
    create_before_destroy = true
  }
}

###################################

# bastion server
resource "aws_instance" "bastion" {
  ami = var.ami_webserver

  # The public SG is added for SSH and ICMP
  vpc_security_group_ids = [aws_security_group.allout_sg.id]
  instance_type          = var.web_servers_type
  key_name               = aws_key_pair.app_keypair.key_name
  subnet_id              = aws_subnet.instances_subnet.id

  tags = {
    Name = "Blue-Green Bastion"
  }
}

resource "aws_eip" "bastion_eip" {
  depends_on = [aws_default_route_table.default_rt]
}

resource "aws_eip_association" "bastion_eip_association" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

output "Bastion_Elastic_IP" {
  value = aws_eip.bastion_eip.public_ip
}

resource "aws_key_pair" "app_keypair" {
  public_key      = file(var.public_keypair_path)
  key_name_prefix = "bg_kp_"
}

##################################
# Security group definitions
# Web server sec group

resource "aws_security_group" "webservers_sg" {
  name   = "webserver-secgroup"
  vpc_id = aws_vpc.bg-vpc.id

  # Internal HTTP access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ssh from anywhere (for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ping access from anywhere
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#public access sg 
# allow all egress traffic (needed for server to download packages)
resource "aws_security_group" "allout_sg" {
  name   = "allout-secgroup"
  vpc_id = aws_vpc.bg-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# LB Sec group definition 
resource "aws_security_group" "lb_sg" {
  name   = "lb-secgroup"
  vpc_id = aws_vpc.bg-vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ping from anywhere
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################

# Creating and attaching the load balancer
# to make LB internal (no floating IP) set internal to true
resource "aws_alb" "alb" {
  name               = "bg-alb"
  subnets            = [aws_subnet.instances_subnet.id]
  internal           = false
  security_groups    = [aws_security_group.lb_sg.id]
  load_balancer_type = "application"
}

output "Blue-Green_ELB_elastic-ip" {
  value = aws_alb.alb.dns_name
}

resource "aws_alb_target_group" "lb_target_group" {
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.bg-vpc.id

  health_check {
    interval            = 20
    path                = "/"
    timeout             = 60
    healthy_threshold   = 4
    unhealthy_threshold = 5
  }
}

resource "aws_alb_listener" "lb_listener" {
  default_action {
    target_group_arn = aws_alb_target_group.lb_target_group.arn
    type             = "forward"
  }
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.bg_asg.id
  alb_target_group_arn   = aws_alb_target_group.lb_target_group.arn

  lifecycle {
    create_before_destroy = true
  }
}

