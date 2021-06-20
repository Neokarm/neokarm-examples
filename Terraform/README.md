# zCompute Terraform Examples

These examples show you how to use the Terraform AWS provider with Zadara zCompute.


## All examples tested with provider.aws v3.0.0 terraform v0.12 and v0.13!
### Examples with rds works with provider.aws v2.13.0


## Important to know

In order to use the aws provider to manage the resources in the cluster, the provider must have a custom endpoints per service.

For example:

```
variable "cluster_api" {
  default     = <Cluster API>
  description = "Cluster API DNS/IP"
}

provider "aws" {
  endpoints {
    ec2 = "https://${var.cluster_api}/api/v2/aws/ec2"
  }

  insecure                    = true
  skip_metadata_api_check     = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true

  # AWS plugin version
  version = "=2.31.0"

  # No importance for this value currently
  region = "us-east-1"
}
```

All the available enpoints can be seen in the the cluster : **Help** > **API Endpoints**


## Before you begin

Before you can use these Terraform examples, you need to:

* First, Perform the setup tasks within zCompute as described bellow.

* Then, edit the sample `terraform.tfvars` file to specify your environment-specific values for various variables.

Each task is described below.

    ```
    aws configure set aws_access_key_id <access_key_id>
    aws configure set aws_secret_access_key <secret_access_key>
    ```
> For load balancing examples: **Ensure that the load balancer service in your cluster is initialized**

## How to use

1. Change the directory to the relvant example

### Before you begin: zCompute setup tasks

Before you can use these Terraform examples, you need to do the following tasks within the zCompute GUI:

1. Log in to the zCompute GUI as a user whose account role is either **Admin** or **Tenant Admin**.

2. Then create a **dedicated VPC-enabled project** for use with Terraform:

    **Menu** > **Identity & Access** > **Accounts** > select an account/**Create**  > **Create Project** > **select existing zCompute edge network for this project.

   
3. **Create a user** that is associated the the project you just created:

    **Menu** > **Account Management** > **Accounts** > select an account > **Users** > **Create User**
    
    **Projects** field: specify the project you just created
    
    **Account Roles** field: specify **Member** and/or **Tenant Admin**
    
        
4. Get the **access and secret keys for the project**:

    Log in to the Symhony GUI as the user you just created.
    
    **Menu** > **Account Management**> **Access Keys** > **Create**
    
    Copy both the access key and the secret key (click the copy icon to the right of each key).
    

5. **Do any additional tasks** that may be required by the scenario you wish to execute. These tasks are described in the readme files for each example. 

### Before you begin: edit `terraform.tfvars`

Each Terraform example includes a sample `terraform.tfvars` file that you can use as a template. For each variable, fill in your environment-specific value.

Access keys can be provided as variables or as path to credentials file.
Example of credentials file:
```
[default]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```
## How to use

1. Run `terraform init`.

2. Run `terraform apply`.

3. If required, enter the relevant variables value.

