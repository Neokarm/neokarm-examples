resource "aws_lb_target_group" "kube_master" {
  name     = "${var.environment}-kube-masters"
  port     = var.k8s_api_server_port
  protocol = "TCP"
  vpc_id   = var.primary_vpc_id

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

resource "aws_lb_target_group" "kube_internal_master" {
  name     = "${var.environment}-kube-internal-masters"
  port     = 9345
  protocol = "TCP"
  vpc_id   = var.primary_vpc_id

  stickiness {
    type = "source_ip"
  }

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "kube_master" {
  default_action {
    target_group_arn = aws_lb_target_group.kube_master.arn
    type             = "forward"
  }

  load_balancer_arn = var.master_load_balancer_id
  port              = var.k8s_api_server_port
  protocol          = "TCP"
}


resource "aws_lb_listener" "kube_internal_master" {
  default_action {
    target_group_arn = aws_lb_target_group.kube_internal_master.arn
    type             = "forward"
  }

  load_balancer_arn = var.master_load_balancer_id
  port              = 9345
  protocol          = "TCP"
}

data "aws_instance" "seeder" {
  filter {
    name   = "tag:Role"
    values = ["seeder"]
  }

  depends_on = [module.seeder_asg]
}

locals {
  master_lb_hostname = var.master_load_balancer_internal_dns != "" ? split(".", var.master_load_balancer_internal_dns)[0] : ""
  seeder_url         = "https://${var.master_load_balancer_internal_dns}:9345"

  rke_san = [
    var.master_load_balancer_public_ip,
    var.master_load_balancer_private_ip,
    local.master_lb_hostname,
    var.master_load_balancer_internal_dns
  ]
}

resource "random_uuid" "random_cluster_id" {}

module "seeder_asg" {
  source             = "./modules/asg"
  group_name         = "${var.environment}-k8s-seeder"
  image_id           = var.primary_k8s_ami_id
  instance_type      = var.k8s_master_instance_type
  key_pair_name      = var.master_key_pair
  rke_cni            = var.k8s_cni
  rke_token          = random_uuid.random_cluster_id.result
  rke_san            = local.rke_san
  taint_servers      = var.taint_masters
  security_groups    = var.primary_security_groups_ids
  subnet_ids         = var.primary_private_subnets_ids
  target_groups_arns = [aws_lb_target_group.kube_master.arn, aws_lb_target_group.kube_internal_master.arn]
  template_file      = "${path.module}/templates/rke-seeder-cloudinit.template.yaml"
  volume_size        = var.k8s_master_volume_size

  max_size     = 1
  min_size     = 1
  desired_size = 1

  instance_tags = [
    {
      key   = "Role"
      value = "seeder"
    },
    {
      key   = "Environment"
      value = var.environment
    }
  ]
}

module "servers_asg" {
  source             = "./modules/asg"
  group_name         = "${var.environment}-k8s-master"
  image_id           = var.primary_k8s_ami_id
  instance_type      = var.k8s_master_instance_type
  key_pair_name      = var.master_key_pair
  rke_cni            = var.k8s_cni
  rke_master_url     = local.seeder_url
  rke_token          = random_uuid.random_cluster_id.result
  rke_san            = local.rke_san
  taint_servers      = var.taint_masters
  security_groups    = var.primary_security_groups_ids
  subnet_ids         = var.primary_private_subnets_ids
  target_groups_arns = [aws_lb_target_group.kube_master.arn, aws_lb_target_group.kube_internal_master.arn]
  template_file      = "${path.module}/templates/rke-server-cloudinit.template.yaml"
  volume_size        = var.k8s_master_volume_size

  max_size     = var.k8s_masters_count - 1
  min_size     = var.k8s_masters_count - 1
  desired_size = var.k8s_masters_count - 1

  instance_tags = [
    {
      key   = "Role"
      value = "server"
    },
    {
      key   = "Environment"
      value = var.environment
    }
  ]

  depends_on = [module.seeder_asg]
}
