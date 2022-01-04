resource "aws_key_pair" "ssh_key" {
  public_key      = file(var.ssh_key_file)
  key_name_prefix = "rke-key"
  lifecycle {
    ignore_changes = [public_key]
  }
}

locals {
  key_name         = aws_key_pair.ssh_key.key_name
  private_key_file = var.ssh_private_key_file
}

