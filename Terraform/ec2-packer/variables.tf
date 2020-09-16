variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret access key"
}

variable "private_key" {
  default     = "packer-example"
  description = "Key pair private key file"
}

variable "public_key" {
  default     = "packer-example.pub"
  description = "Key pair public key file"
}

variable "ami_name" {
  default     = "centos"
  description = "Instance image name"
}

variable "ssh_username" {
  default     = "centos"
  description = "Builders SSH user name"
}

variable "symphony_ip" {
  description = "Cluster API IP address"
}

variable "instance_type" {
  default     = "t2.medium"
  description = "Instacne type"
}
