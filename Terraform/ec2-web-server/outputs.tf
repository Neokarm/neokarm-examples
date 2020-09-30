
output "publicaddress" {
  value = ["${aws_instance.web.*.public_ip}"]
}
