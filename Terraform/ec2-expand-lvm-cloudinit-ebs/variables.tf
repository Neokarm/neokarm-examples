# Region Credentials
variable "zCompute_ip" {}
variable "secret_key" {}
variable "access_key" {}
variable "credentials_file" {
  default = "~/.aws/credentials"
}

variable "instance_image" {}

variable "public_keypair_path" {}
variable "instance_type" {
  default = "t2.medium"
}

