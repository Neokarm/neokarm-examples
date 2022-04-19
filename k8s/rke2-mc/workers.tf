module "workers_asg" {
  source          = "./modules/asg"
  group_name      = "${var.environment}-k8s-worker"
  image_id        = var.primary_k8s_ami_id
  instance_type   = var.k8s_worker_instance_type
  key_pair_name   = var.primary_worker_key_pair
  rke_cni         = var.k8s_cni
  rke_master_url  = local.seeder_url
  rke_token       = random_uuid.random_cluster_id.result
  security_groups = var.primary_security_groups_ids
  subnet_ids      = var.primary_private_subnets_ids
  template_file   = "${path.module}/templates/rke-agent-cloudinit.template.yaml"
  volume_size     = var.k8s_worker_volume_size

  max_size     = var.primary_k8s_workers_count
  min_size     = var.primary_k8s_workers_count
  desired_size = var.primary_k8s_workers_count

  instance_tags = [
    {
      key   = "Role"
      value = "agent"
    },
    {
      key   = "Environment"
      value = var.environment
    }
  ]
  node_labels = [
    "worker-role=primary"
  ]

  depends_on = [module.seeder_asg]
}

module "secondary_workers_asg" {
  count           = var.secondary_k8s_workers_count > 0 ? 1 : 0
  source          = "./modules/asg"
  group_name      = "${var.environment}-k8s-secondary-worker"
  image_id        = var.secondary_k8s_ami_id
  instance_type   = var.secondary_k8s_worker_instance_type
  key_pair_name   = var.secondary_worker_key_pair
  rke_cni         = var.k8s_cni
  rke_master_url  = local.seeder_url
  rke_token       = random_uuid.random_cluster_id.result
  security_groups = var.secondary_security_groups_ids
  subnet_ids      = var.secondary_private_subnets_ids
  template_file   = "${path.module}/templates/rke-agent-cloudinit.template.yaml"
  volume_size     = var.k8s_worker_volume_size

  max_size     = var.secondary_k8s_workers_count
  min_size     = var.secondary_k8s_workers_count
  desired_size = var.secondary_k8s_workers_count

  providers = {
    aws = aws.secondary
  }

  instance_tags = [
    {
      key   = "Role"
      value = "agent"
    },
    {
      key   = "Environment"
      value = var.environment
    }
  ]
  node_labels = [
    "worker-role=secondary"
  ]

  depends_on = [module.seeder_asg]
}