# Sample tfvars file 
# Stratoscale Symphony credentials

symphony_ip = "10.16.146.60"
access_key = "cc435c1049b4400190053fca55b77558"
secret_key = "c14c3c28bfe040afa75ded3be40f3d98"

# Number of web servers (Load balancer will automatically manage target groups)
web_number = "2"

# Use Public Xenial cloud image ami
# Recommend use of Xenial's latest cloud image
# located here: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
web_ami = "ami-6eaa580038b645eebb5269aef05ace4f"
web_instance_type = "t2.medium"
public_keypair_path = "/home/harel/keys.pub"

#Database Information (wordpress containe will use wordpress database by default)

db_user = "admin"
db_password = "Stratoscale!Orchestration!"




