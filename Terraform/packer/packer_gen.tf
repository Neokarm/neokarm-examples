data "template_file" "packer_template" {
  template = file("./packer_gen.template")

  vars = {
    aws_access_key       = var.access_key
    aws_secret_key       = var.secret_key
    zCompute_ip          = var.zCompute_ip
    subnet_id            = aws_subnet.pub_subnet.id
    vpc_id               = aws_vpc.app_vpc.id
    sg_ids               = "\"${aws_security_group.ssh-sg.id}\",\"${aws_security_group.sg-any.id}\""
    kp_name              = aws_key_pair.app_keypair.key_name
    bastion_public_ip    = aws_eip.bastion-eip.public_ip
    bastion_user_name    = var.bastion_user_name
    private_keypair_path = var.private_keypair_path
    packer_user_name     = var.packer_user_name
    packer_ami_image     = var.packer_ami_image
  }
}

resource "local_file" "packer_gen" {
  content  = data.template_file.packer_template.rendered
  filename = "packer_generated.json"
}

