# Create instances, and name them according to count

# Defining cloud config template file 

data "template_file" "ebsdeploy"{
  template = file("./cloudconfig.cfg")
}

data "template_cloudinit_config" "ebsdeploy_config" {
  gzip = false
  base64_encode = false

  part {
    filename     = "cloudconfig.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.ebsdeploy.rendered
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file(var.public_keypair_path)
}

resource "aws_instance" "ec2_instance" {
    ami = var.instance_image
    key_name = aws_key_pair.ssh_key.key_name
    tags = {
        Name= "instance_expanded"
    }
    
    instance_type = var.instance_type
   

    user_data = data.template_cloudinit_config.ebsdeploy_config.rendered

    root_block_device { 
        # Enter larger volume size here in GB, must be larger than images base size
        volume_size = 200
    }
}
resource "aws_eip" "public_ip" {
 instance = aws_instance.ec2_instance.id
 vpc = true
 depends_on = [aws_instance.ec2_instance]
}


