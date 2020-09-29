# .tfvars Sample File


# Region Credentials
symphony_ip = "10.16.145.148"
access_key = "bdd186038381477c8e7d81f3390a7f45"
secret_key = "c48fae294b14425aa75de75d7b286134"

# Recommended use of Xenial's latest cloud image
# located here: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img 

ami_webserver = "ami-858c4d1a2e4c4139824db7148c05d1bc"
public_keypair_path = "/home/harel/.ssh/id_rsa.pub"

# optional
# instance_type = "<instance-type>"
# instance_number = <number of instances>
