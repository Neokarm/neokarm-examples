# RDS Simple Example
## This example works with aws provider version v2.13.0!
This example demonstrates creating an RDS instance using terraform, it will create an instance  
and assign it with a custom parameters group with modified parameters.

> Note: This example will provision a MySQL 5.7 version

## Getting started
1. Make sure you have the database engine you want to provision is enabled in zCompute.
2. Make sure you have the applicable terraform installed
3. Modify the `terraform.tfvars` file according to your environment variables
4. Run `terraform init`
5. Run `terraform apply`
