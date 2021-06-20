# Region Credentials
variable "zCompute_ip" {}
variable "secret_key" {}
variable "access_key" {}
variable "credentials_file" {
  default = "~/.aws/credentials"
}


# Main variables
variable "ami_webserver" {}
variable "public_keypair_path" {}
variable "web_servers_number" {
  default = 2
}
variable "web_servers_type" {
  default = "t2.small"
}
