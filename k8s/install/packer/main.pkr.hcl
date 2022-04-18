packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "centos" {
  ami_name                     = "rke2-centos-{{timestamp}}"
  instance_type                = var.instance_type
  region                       = "symphony"
  custom_endpoint_ec2          = "https://${var.zcompute_api}/api/v2/aws/ec2"
  insecure_skip_tls_verify     = true
  communicator                 = "ssh"
  source_ami                   = var.ami_id
  ssh_username                 = var.ssh_username
  subnet_id                    = var.subnet_id
  ssh_interface                = "private_ip"
  ssh_private_key_file         = var.private_keypair_path
  ssh_bastion_host             = var.bastion_public_ip
  ssh_bastion_port             = 22
  ssh_bastion_username         = var.ssh_bastion_username
  ssh_bastion_private_key_file = var.private_keypair_path
  ssh_keypair_name             = var.ssh_keypair_name

  tag {
    key   = "rke2-version"
    value = var.rke2_version
  }
  tag {
    key   = "last-build"
    value = formatdate("DD-MMM-YY", timestamp())
  }
}

build {
  name = "rke2-centos"
  sources = [
    "source.amazon-ebs.centos"
  ]

  ## Disk mapper script for EBS csi driver
  provisioner "file" {
    content = templatefile("../../extra/disk-mapper/symphony_disk_mapper.template.py", {
      symphony_ec2_endpoint = "https://${var.zcompute_api}/api/v2/aws/ec2"
    })
    destination = "/tmp/symphony_disk_mapper.py"
  }

  provisioner "file" {
    source      = "../../extra/disk-mapper/symphony_disk_mapper.rules"
    destination = "/tmp/symphony_disk_mapper.rules"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/symphony_disk_mapper.py /usr/bin/symphony_disk_mapper.py",
      "sudo chmod +x /usr/bin/symphony_disk_mapper.py",
      "sudo cp /tmp/symphony_disk_mapper.rules /etc/udev/rules.d/symphony_disk_mapper.rules",
    ]
  }

  # RKE2 configuration and installation
  provisioner "file" {
    source      = "files/rke2containerd.sh"
    destination = "/tmp/rke2containerd.sh"
  }

  provisioner "file" {
    source      = "files/rke.conf"
    destination = "/tmp/rke.conf"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/rke2containerd.sh /etc/profile.d/rke2containerd.sh",
      "sudo cp /tmp/rke.conf /etc/NetworkManager/conf.d/rke.conf",
    ]
  }

  provisioner "file" {
    source      = "files/setup_rke2_node.sh"
    destination = "/tmp/setup_rke2_node.sh"
  }

  # Download rke2 installation script
  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/setup_rke2_node.sh",
      "sudo INSTALL_RKE2_VERSION=${var.rke2_version} /tmp/setup_rke2_node.sh",
    ]
  }

  provisioner "file" {
    source      = "files/start_rke2_node.sh"
    destination = "/tmp/start_rke2_node.sh"
  }

  provisioner "file" {
    source      = "files/wait_for_rke2_node.sh"
    destination = "/tmp/wait_for_rke2_node.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/start_rke2_node.sh /usr/bin/start_rke2_node.sh",
      "sudo chmod +x /usr/bin/start_rke2_node.sh",
      "sudo cp /tmp/wait_for_rke2_node.sh /usr/bin/wait_for_rke2_node.sh",
      "sudo chmod +x /usr/bin/wait_for_rke2_node.sh"
    ]
  }
}