resource "aws_launch_configuration" "rke" {
  image_id        = var.image_id
  instance_type   = var.instance_type
  key_name        = var.key_pair_name
  security_groups = var.security_groups

  user_data = templatefile(var.template_file, {
    random_uuid   = var.rke_token
    seeder_url    = var.rke_master_url
    cni           = var.rke_cni
    san           = var.rke_san
    taint_servers = var.taint_servers
    node_labels   = var.node_labels
  })

  root_block_device {
    delete_on_termination = "true"
    encrypted             = "false"
    volume_size           = var.volume_size
    volume_type           = var.volume_type
  }

  lifecycle {
    ignore_changes        = [user_data, root_block_device, metadata_options, ebs_block_device]
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "rke" {
  name                 = var.group_name
  launch_configuration = aws_launch_configuration.rke.id
  termination_policies = ["OldestInstance", "NewestInstance", "OldestLaunchConfiguration", "Default"]

  max_size            = var.min_size
  min_size            = var.max_size
  desired_capacity    = var.desired_size
  vpc_zone_identifier = var.subnet_ids

  target_group_arns = var.target_groups_arns

  dynamic "tag" {
    for_each = var.instance_tags
    content {
      key                 = tag.value["key"]
      value               = tag.value["value"]
      propagate_at_launch = true
    }
  }
}