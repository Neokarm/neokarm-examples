variable "ubuntu_ami" {}
variable "secret_key" {
  default = ""
}
variable "access_key" {
  default = ""
}
variable "credentials_file" {
  default = "~/.aws/credentials"
}

variable "zCompute_ip" {}
variable "key_name" {}
variable "sg_web_servers" {}
variable "instances_count" {
  default = 3
}
