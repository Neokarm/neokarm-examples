variable "symphony_ip" {
  description = "Cluster API IP address"
}
variable "secret_key" {}
variable "access_key" {}
#variable "creds_file" {}
variable "ami_image" {
  description = "Instance image ID"
}

variable "quantity" {
  default     = 3
  description = "Number of instances"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Instacne type"
}

