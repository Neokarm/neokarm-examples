# Region Credentials
variable "symphony_ip" {}
variable "secret_key" {}
variable "access_key" {}
# variable "credentials_file" {}
variable "instance_image" {}

variable "public_keypair_path" {}
variable "instance_type" {
  default = "t2.medium"
}

