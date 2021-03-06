# .tfvars Sample File

# Region Credentia
zCompute_ip = "<zCompute_ip>"
access_key  = "<access_key>"
secret_key  = "<secret_key>"
# credentials_file = "<path_to creds_file>"

# Recommend use of Xenial's latest cloud image
# located here: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img 

ami_webserver = "<image_id>"

# default lb type is application load balancer
# in order to create Network load balancer, delete begining ladders of those 2 variables:
# lb_type = "network"
# protocol = "TCP"


# optional
# web_servers_type = "<instance-type>"
# web_servers_number = <number of instances>
