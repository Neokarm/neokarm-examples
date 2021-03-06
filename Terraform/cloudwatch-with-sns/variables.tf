variable "secret_key" {}
variable "access_key" {}
variable "zCompute_ip" {}
variable "aws_ami" {}
variable "credentials_file" {
  default = "~/.aws/credentials"
}

variable "instance_count" {
  default = 1
}
variable "instance_type" {
  default = "t2.micro"
}
variable "cloudwatch_alarm_prefix" {
  default = "cloudwatch_alarm_"
}

variable "sns_topic_name_prefix" {
  description = "The prefix of the SNS Topic name to send events to"
  default     = "tf-example-sns-topic"
}
variable "user_id" {
  default = "admin"
}
