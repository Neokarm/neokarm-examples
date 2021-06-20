# Region Credentials
variable "zCompute_ip" {}
variable "secret_key" {}
variable "access_key" {}
variable "credentials_file" {
  default = "~/.aws/credentials"
}

variable "ami_image" {}
variable "instance_number" {
  default = 1
}
variable "instance_type" {
  default = "t2.micro"
}

