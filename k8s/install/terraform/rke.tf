resource "random_uuid" "random_cluster_id" {}

resource "aws_instance" "rke_bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = local.key_name

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.default.id, aws_security_group.bastion_sg.id]
  tags = {
    Name        = "${var.environment}-bastion"
    Environment = "${var.environment}"
  }
}
resource "aws_eip_association" "rke_bastion_eip" {
  depends_on           = [aws_route_table_association.public, aws_route.public_internet_gateway]
  network_interface_id = aws_instance.rke_bastion.primary_network_interface_id
  allocation_id        = aws_eip.bastion_eip.id
}

resource "aws_lb" "rke_master_lb" {
  depends_on         = [aws_route_table_association.public, aws_route.public_internet_gateway, aws_internet_gateway.ig]
  name               = "${var.environment}-master-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]
  security_groups    = [aws_security_group.default.id]
  tags = {
    Name        = "${var.environment}-master-lb"
    Environment = "${var.environment}"
  }
}

locals {
  rke_master_lb_hostname = split(".", "${aws_lb.rke_master_lb.dns_name}")[0]
}

resource "null_resource" "lb_ip_getter" {
  depends_on = [aws_eip_association.rke_bastion_eip,
    aws_instance.rke_bastion,
  aws_lb.rke_master_lb]

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = file(local.private_key_file)
    host        = aws_eip.bastion_eip.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y bind-utils"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dig ${local.rke_master_lb_hostname} +short > lb_ip.txt"
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.private_key_file} centos@${aws_eip.bastion_eip.public_ip}:~/lb_ip.txt lb_ip.txt"
  }

}

data "local_file" "lb_private_ip" {
  depends_on = [null_resource.lb_ip_getter]
  filename   = "lb_ip.txt"
}

data "aws_network_interface" "lb_interface" {
  filter {
    name   = "private-ip-address"
    values = [trimspace(data.local_file.lb_private_ip.content)]
  }
}

locals {
  lb_public_ip = one(data.aws_network_interface.lb_interface[*].association[0].public_ip)
  rke_san      = [aws_lb.rke_master_lb.dns_name, "${local.rke_master_lb_hostname}.symphony.local", local.rke_master_lb_hostname, local.lb_public_ip]
}

resource "aws_instance" "rke_seeder" {
  depends_on    = [aws_lb.rke_master_lb, aws_route_table_association.private, aws_route.private_nat_gateway]
  ami           = var.ami_id
  instance_type = var.server_instance_type
  user_data = templatefile("rke-seeder-cloudinit.template.yml", {
    random_uuid   = random_uuid.random_cluster_id.result,
    hostname      = "rke2-server-1.${aws_route53_zone.main.name}"
    san           = local.rke_san
    taint_servers = var.taint_servers
  })
  key_name = local.key_name

  root_block_device {
    delete_on_termination = "true"
    tags = {
      Name        = "${var.environment}-server-1"
      Environment = "${var.environment}"
    }
    encrypted   = "false"
    volume_size = "250"
    volume_type = "gp3"
  }

  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.default.id]

  tags = {
    Name        = "${var.environment}-server-1"
    Environment = "${var.environment}"
  }
  iam_instance_profile = aws_iam_instance_profile.full_ec2_access_profile.name

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "null_resource" "rke-seeder-provisioning" {
  depends_on = [aws_eip_association.rke_bastion_eip,
    aws_instance.rke_seeder,
    aws_instance.rke_bastion,
  aws_route53_record.cluster]

  connection {
    type                = "ssh"
    bastion_host        = aws_eip.bastion_eip.public_ip
    bastion_user        = "centos"
    bastion_private_key = file(local.private_key_file)
    user                = "centos"
    private_key         = file(local.private_key_file)
    host                = aws_instance.rke_seeder.private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/cloud-init-done ]; do echo Waiting for cloud-init to finish; sleep 1; done",
      "sleep 30"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -c \"grep -qxF 'kubelet-arg:' /etc/rancher/rke2/config.yaml || echo 'kubelet-arg: provider-id=ec2://symphony/${aws_instance.rke_seeder.id}' >> /etc/rancher/rke2/config.yaml\""
    ]
  }

  provisioner "file" {
    content = templatefile("../../extra/disk-mapper/symphony_disk_mapper.template.py", {
      symphony_ec2_endpoint = "https://${var.zcloud_hostname}/api/v2/aws/ec2"
    })
    destination = "/tmp/symphony_disk_mapper.py"
  }

  provisioner "file" {
    source      = "../certificates/ca.crt"
    destination = "/tmp/${aws_route53_zone.main.name}.ca.crt"
  }

  provisioner "file" {
    source      = "../../extra/disk-mapper/symphony_disk_mapper.rules"
    destination = "/tmp/symphony_disk_mapper.rules"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/symphony_disk_mapper.py /usr/bin/symphony_disk_mapper.py",
      "sudo cp /tmp/${aws_route53_zone.main.name}.ca.crt /usr/share/pki/ca-trust-source/anchors/",
      "sudo cp /tmp/symphony_disk_mapper.rules /etc/udev/rules.d/symphony_disk_mapper.rules",
      "sudo chmod +x /usr/bin/symphony_disk_mapper.py",
      "sudo update-ca-trust",
      "echo RKE Seeder > /tmp/i_was_here",
      "while [ ! -x /usr/bin/install-rke2.sh ]; do echo rke2 installer not ready; sleep 1; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/centos/.ssh",
      "[ -f /home/centos/.ssh/id_rsa ] || ssh-keygen -t rsa -b 4096 -f /home/centos/.ssh/id_rsa -q -N ''"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo INSTALL_RKE2_VERSION=${var.rke_version} /usr/bin/install-rke2.sh",
      "sudo systemctl enable rke2-server",
      "sudo systemctl start rke2-server --no-block"
    ]
  }
}

resource "null_resource" "wait-for-rke-seeder" {
  depends_on = [null_resource.rke-seeder-provisioning]

  connection {
    type                = "ssh"
    bastion_host        = aws_eip.bastion_eip.public_ip
    bastion_user        = "centos"
    bastion_private_key = file(local.private_key_file)
    user                = "centos"
    private_key         = file(local.private_key_file)
    host                = aws_instance.rke_seeder.private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /usr/bin/wait_for_rke.sh"
    ]
  }
}

resource "aws_instance" "rke_servers" {
  depends_on    = [aws_lb.rke_master_lb, aws_route_table_association.private, aws_route.private_nat_gateway, aws_instance.rke_seeder]
  count         = var.rke_servers_count - 1
  ami           = var.ami_id
  instance_type = var.server_instance_type
  user_data = templatefile("rke-server-cloudinit.template.yml", {
    random_uuid   = random_uuid.random_cluster_id.result,
    seeder_url    = "https://${aws_instance.rke_seeder.private_ip}:9345",
    san           = local.rke_san
    hostname      = "rke2-server-${count.index + 2}.${aws_route53_zone.main.name}"
    taint_servers = var.taint_servers
  })

  key_name             = local.key_name
  iam_instance_profile = aws_iam_instance_profile.full_ec2_access_profile.name

  root_block_device {
    delete_on_termination = "true"
    tags = {
      Name        = "${var.environment}-server-${count.index + 2}"
      Environment = "${var.environment}"
    }
    encrypted   = "false"
    volume_size = "250"
    volume_type = "gp3"
  }

  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.default.id]
  tags = {
    Name        = "${var.environment}-server-${count.index + 2}"
    Environment = "${var.environment}"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "null_resource" "rke-servers-provisioner" {
  depends_on = [aws_instance.rke_servers, null_resource.wait-for-rke-seeder]
  count      = var.rke_servers_count - 1
  triggers = {
    run = aws_instance.rke_servers[count.index].id
  }
  connection {
    type                = "ssh"
    bastion_host        = aws_eip.bastion_eip.public_ip
    bastion_user        = "centos"
    bastion_private_key = file(local.private_key_file)
    user                = "centos"
    private_key         = file(local.private_key_file)
    host                = aws_instance.rke_servers[count.index].private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/cloud-init-done ]; do echo Waiting for cloud-init to finish; sleep 1; done",
      "sleep 30"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -c \"grep -qxF 'kubelet-arg:' /etc/rancher/rke2/config.yaml || echo 'kubelet-arg: provider-id=ec2://symphony/${aws_instance.rke_servers[count.index].id}' >> /etc/rancher/rke2/config.yaml\""
    ]
  }

  provisioner "file" {
    content = templatefile("../../extra/disk-mapper/symphony_disk_mapper.template.py", {
      symphony_ec2_endpoint = "https://${var.zcloud_hostname}/api/v2/aws/ec2"
    })
    destination = "/tmp/symphony_disk_mapper.py"
  }

  provisioner "file" {
    source      = "../certificates/ca.crt"
    destination = "/tmp/${aws_route53_zone.main.name}.ca.crt"
  }

  provisioner "file" {
    source      = "../../extra/disk-mapper/symphony_disk_mapper.rules"
    destination = "/tmp/symphony_disk_mapper.rules"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/symphony_disk_mapper.py /usr/bin/symphony_disk_mapper.py",
      "sudo cp /tmp/${aws_route53_zone.main.name}.ca.crt /usr/share/pki/ca-trust-source/anchors/",
      "sudo cp /tmp/symphony_disk_mapper.rules /etc/udev/rules.d/symphony_disk_mapper.rules",
      "sudo chmod +x /usr/bin/symphony_disk_mapper.py",
      "sudo update-ca-trust",
      "echo RKE Seeder > /tmp/i_was_here",
      "while [ ! -x /usr/bin/install-rke2.sh ]; do echo rke2 installer not ready; sleep 1; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo INSTALL_RKE2_VERSION=${var.rke_version} /usr/bin/install-rke2.sh",
      "sudo systemctl enable rke2-server",
      "sudo systemctl start rke2-server --no-block"
    ]
  }
}

resource "aws_instance" "rke_agents" {
  depends_on    = [aws_lb.rke_master_lb, aws_route_table_association.private, aws_route.private_nat_gateway, aws_instance.rke_seeder]
  count         = var.rke_agents_count
  ami           = var.ami_id
  instance_type = var.agent_instance_type
  user_data = templatefile("rke-agent-cloudinit.template.yml", {
    random_uuid = random_uuid.random_cluster_id.result,
    seeder_url  = "https://${aws_instance.rke_seeder.private_ip}:9345",
    san         = local.rke_san
    hostname    = "rke2-agent-${count.index + 1}.${aws_route53_zone.main.name}"
  })

  key_name             = local.key_name
  iam_instance_profile = aws_iam_instance_profile.full_ec2_access_profile.name

  root_block_device {
    delete_on_termination = "true"
    tags = {
      Name        = "${var.environment}-agent-${count.index + 1}"
      Environment = "${var.environment}"
    }
    encrypted   = "false"
    volume_size = "250"
    volume_type = "gp3"
  }

  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.default.id]
  tags = {
    Name        = "${var.environment}-agent-${count.index + 1}"
    Environment = "${var.environment}"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "null_resource" "rke-agents-provisioner" {
  depends_on = [aws_instance.rke_agents, null_resource.wait-for-rke-seeder]
  count      = var.rke_agents_count
  triggers = {
    run = aws_instance.rke_agents[count.index].id
  }
  connection {
    type                = "ssh"
    bastion_host        = aws_eip.bastion_eip.public_ip
    bastion_user        = "centos"
    bastion_private_key = file(local.private_key_file)
    user                = "centos"
    private_key         = file(local.private_key_file)
    host                = aws_instance.rke_agents[count.index].private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/cloud-init-done ]; do echo Waiting for cloud-init to finish; sleep 1; done",
      "sleep 30"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -c \"grep -qxF 'kubelet-arg:' /etc/rancher/rke2/config.yaml || echo 'kubelet-arg: provider-id=ec2://symphony/${aws_instance.rke_agents[count.index].id}' >> /etc/rancher/rke2/config.yaml\""
    ]
  }

  provisioner "file" {
    content = templatefile("../../extra/disk-mapper/symphony_disk_mapper.template.py", {
      symphony_ec2_endpoint = "https://${var.zcloud_hostname}/api/v2/aws/ec2"
    })
    destination = "/tmp/symphony_disk_mapper.py"
  }

  provisioner "file" {
    source      = "../certificates/ca.crt"
    destination = "/tmp/${aws_route53_zone.main.name}.ca.crt"
  }

  provisioner "file" {
    source      = "../../extra/disk-mapper/symphony_disk_mapper.rules"
    destination = "/tmp/symphony_disk_mapper.rules"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/symphony_disk_mapper.py /usr/bin/symphony_disk_mapper.py",
      "sudo cp /tmp/${aws_route53_zone.main.name}.ca.crt /usr/share/pki/ca-trust-source/anchors/",
      "sudo cp /tmp/symphony_disk_mapper.rules /etc/udev/rules.d/symphony_disk_mapper.rules",
      "sudo chmod +x /usr/bin/symphony_disk_mapper.py",
      "sudo update-ca-trust",
      "echo RKE Seeder > /tmp/i_was_here",
      "while [ ! -x /usr/bin/install-rke2.sh ]; do echo rke2 installer not ready; sleep 1; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo INSTALL_RKE2_VERSION=${var.rke_version} INSTALL_RKE2_TYPE=agent /usr/bin/install-rke2.sh",
      "sudo systemctl enable rke2-agent",
      "sudo systemctl start rke2-agent --no-block"
    ]
  }
}

resource "null_resource" "rke2-config" {
  depends_on = [null_resource.wait-for-rke-seeder]

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = file(local.private_key_file)
    host        = aws_eip.bastion_eip.public_ip
  }
  provisioner "file" {
    content     = file(local.private_key_file)
    destination = "/home/centos/private_key"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/private_key",
      "rm -f ca-certificates.crt kubeconfig.yaml",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/private_key centos@${aws_instance.rke_seeder.private_ip}:/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ca-certificates.crt",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/private_key centos@${aws_instance.rke_seeder.private_ip}:/etc/rancher/rke2/rke2.yaml kubeconfig.yaml",
    ]
  }
  provisioner "local-exec" {
    command = "rm -f ca-certificates.crt kubeconfig.yaml"
  }
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.private_key_file} centos@${aws_eip.bastion_eip.public_ip}:~/kubeconfig.yaml kubeconfig.yaml"
  }
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.private_key_file} centos@${aws_eip.bastion_eip.public_ip}:~/ca-certificates.crt ca-certificates.crt"
  }
  provisioner "local-exec" {
    command = "sed -i 's#server:.*#server: https://${local.lb_public_ip}:6443/#' kubeconfig.yaml"
  }
}

output "rke_master_loadbalancer_dns" {
  value = aws_lb.rke_master_lb.dns_name
}

output "rke_bastion_eip" {
  value = aws_eip.bastion_eip.public_ip
}

output "rke_server_ips" {
  value = concat([aws_instance.rke_seeder.private_ip], aws_instance.rke_servers[*].private_ip)
}

output "rke_agent_ips" {
  value = aws_instance.rke_agents[*].private_ip
}

output "rke_config_filename" {
  value = "kubeconfig.yaml"
}

resource "aws_route53_record" "rke-seeder" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "rke2-server-1.${aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.rke_seeder.private_ip]
}

resource "aws_route53_record" "rke-servers" {
  count   = var.rke_servers_count - 1
  zone_id = aws_route53_zone.main.zone_id
  name    = "rke2-server-${count.index + 2}.${aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.rke_servers[count.index].private_ip]
}

resource "aws_route53_record" "rke-agents" {
  count   = var.rke_agents_count
  zone_id = aws_route53_zone.main.zone_id
  name    = "rke2-agent-${count.index + 1}.${aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.rke_agents[count.index].private_ip]
}

resource "aws_lb_target_group" "rke-masters-target-group" {
  name     = "${var.environment}-masters-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

// workaround terraform ARN validation
data "aws_lb_target_group" "rke-masters-target-group" {
  name = aws_lb_target_group.rke-masters-target-group.name
}

resource "aws_lb_target_group_attachment" "rke-master-tg-seeder-attachment" {
  target_group_arn = data.aws_lb_target_group.rke-masters-target-group.arn
  target_id        = aws_instance.rke_seeder.id
}

resource "aws_lb_target_group_attachment" "rke-master-tg-servers-attachment" {
  count            = length(aws_instance.rke_servers)
  target_group_arn = data.aws_lb_target_group.rke-masters-target-group.arn
  target_id        = aws_instance.rke_servers[count.index].id
}

# Terraform fails to create this resource because of ARN validation done by the AWS provider - needs manual intervention

# resource "aws_alb_listener" "rke-master-listener" {
#   default_action {
#     target_group_arn = data.aws_lb_target_group.rke-masters-target-group.arn
#     type             = "forward"
#   }
#   load_balancer_arn = data.aws_lb.rke_master_lb.id
#   port              = 6443
#   protocol          = "TCP"
# }
