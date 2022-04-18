# zCompute cluster configuration
zcompute_api = "cloud.zadara.net" # zCompute API IP/Host address

# Access keys for the keypair
ssh_key_file_path        = "~/.ssh/id_rsa"
ssh_public_key_file_path = "~/.ssh/id_rsa.pub"

# RKE2 node configuration
rke2_ami_id   = "ami-b3f150f6f0734fce873d3149e5fe28f7"
node_username = "centos"

# Bastion configuration
bastion_ami_id   = "ami-c4dcb775e5ba45dda5a7f499955ce510"
bastion_username = "centos"