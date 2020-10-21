# Region Credentials
variable "symphony_ip" {}
#when providing public and secret keys as variables delete ladders
#variable "secret_key" {}
#variable "access_key" {}

# Main variables
variable "ami_image" {}
variable "instance_number" {
  default = 1
}
variable "instance_type" {
  default = "t2.micro"
}