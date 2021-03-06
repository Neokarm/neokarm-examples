# Overview - EC2 Web Server
This terraform example will create 3 ubuntu instances, and install nginx on them using userdata.sh.
The userdata.sh script will also query the metadata service in order to present the instnace ID in the nginx web server.
To get the ami id, simply fetch the image uuid from the zCompute UI, and convert it to the AWS format:
`ami-<uuid without dashes>`

## Getting started
1. Make sure you have the required terraform version installed
2. Make sure to use an ubuntu cloud image. Grab one [here](https://cloud-images.ubuntu.com/zesty/current/zesty-server-cloudimg-amd64.img)
3. Create/Import a keypair in zCompute
4. Create/Specify a security group
5. Modify the `terraform.tfvars` file according to your environment
6. Run `terraform init`
7. Run `terraform apply`

