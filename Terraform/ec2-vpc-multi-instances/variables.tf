# Region Credentials
variable "zCompute_ip" {}
#when providing public and secret keys as variables delete ladders
variable "secret_key" {
  default = ""
}
variable "access_key" {
  default = ""
}
variable "credentials_file" {
  default = "~/.aws/credentials"
}

# Main variables
variable "ami_image" {}
variable "instance_number" {
  default = 3
}
variable "instance_type" {
  default = "t2.micro"
}
