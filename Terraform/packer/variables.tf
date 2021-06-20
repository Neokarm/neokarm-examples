# Region Credentials
variable "zCompute_ip" {
}

variable "secret_key" {
}

variable "access_key" {
}
variable "credentials_file" {
  default = "~/.aws/credentials"
}

variable "bastion_ami_image" {
}

variable "bastion_user_name" {
}

variable "public_bastion_keypair_path" {
}

variable "public_keypair_path" {
}

variable "private_keypair_path" {
}

variable "packer_ami_image" {
}

variable "packer_user_name" {
}

