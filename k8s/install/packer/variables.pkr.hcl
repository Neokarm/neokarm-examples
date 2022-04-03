variable "ami_id" {
  type        = string
  description = "ID (in AWS format) of the base image"
}

variable "zcompute_api" {
  type        = string
  description = "IP/DNS of the zCompute cluster API endpoint"
}

variable "ssh_username" {
  type        = string
  description = "The ssh username for the packer builder"
}

variable "subnet_id" {
  type        = string
  description = "ID (in AWS format) of the subnet you want to provision the packer in"
}

variable "instance_type" {
  type        = string
  default     = "z4.large"
  description = "The builder instance type"
}

variable "private_keypair_path" {
  type        = string
  description = "Keypair private key path"
}

variable "bastion_public_ip" {
  type        = string
  description = "Bastion IP for ssh"
}

variable "ssh_bastion_username" {
  type        = string
  description = "Bastion ssh username"
}

variable "ssh_keypair_name" {
  type        = string
  description = "Keypair name to use for the packer builder"
}

variable "rke2_version" {
  type        = string
  default     = "v1.23.4+rke2r1"
  description = "RKE2 version"
}