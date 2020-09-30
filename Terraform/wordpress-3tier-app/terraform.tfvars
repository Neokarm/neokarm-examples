# Sample tfvars file 
# Neokarm Symphony credentials

symphony_ip = "<symphony-ip>"
access_key = "<access-key>"
secret_key = "<secret-key>"

# Number of web servers (Load balancer will automatically manage target groups)
web_number = "2"

# Use Public Xenial cloud image ami
# Recommend use of Xenial's latest cloud image
# located here: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
web_ami = "<image id>"
web_instance_type = "t2.medium"
public_keypair_path = "<path to file>"

#Database Information (wordpress container will use wordpress database by default)

db_user = "admin"
db_password = "Neokarm!Orchestration!"




