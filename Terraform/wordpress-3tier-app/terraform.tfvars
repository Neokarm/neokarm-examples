# Sample tfvars file 
# Zadara zCompute credentials

zCompute_ip = "<zCompute_ip>"
access_key  = "<access_key>"
secret_key  = "<secret_key>"
#credentials_file = "<path_to_creds_file>"

# Number of web servers (Load balancer will automatically manage target groups)
web_number = "2"

# Use Public Xenial cloud image ami
# Recommend use of Xenial's latest cloud image
# located here: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
web_ami             = "<image_id>"
web_instance_type   = "t2.medium"
public_keypair_path = "<path_to_key.pub>"

#Database Information (wordpress container will use wordpress database by default)

db_user     = "admin"
db_password = "Zadara!Orchestration!"
