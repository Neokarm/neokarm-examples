# Symphony Terraform Examples

These examples show you how to use the Terraform AWS provider with Neokarm Symphony.

## All examples tested with provider.aws v3.0.0 terraform v0.12 and v0.13!
## Before you begin

Before you can use these Terraform examples, you need to:

* First, Perform the setup tasks within Symphony as described bellow.

* Then, edit the sample `terraform.tfvars` file to specify your environment-specific values for various variables.

Each task is described below.


### Before you begin: Symphony setup tasks

Before you can use these Terraform examples, you need to do the following tasks within the Symphony GUI:

1. Log in to the Symphony GUI as a user whose account role is either Admin or Tenant Admin.

2. Then create a **dedicated VPC-enabled project** for use with Terraform:

    **Menu** > **Account Management** > **Accounts** > select an account > **Create Project** > **Enable VPC** > select existing Symphony edge network for this project.

   
3. **Create a user** that is associated the the project you just created:

    **Menu** > **Account Management** > **Accounts** > select an account > **Users** > **Create User**
    
    **Projects** field: specify the project you just created
    
    **Account Roles** field: specify **Member** and/or **Tenant Admin**
    
        
4. Get the **access and secret keys for the project**:

    Log in to the Symhony GUI as the user you just created.
    
    **Menu** > **Account Management**> **Access Keys** > **Create**
    
    Copy both the access key and the secret key (click the copy icon to the right of each key).
    

5. **Do any additional tasks** that may be required for whatever specific Terraform examples you plan to use. These tasks are described in the readme files for each example. 

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
