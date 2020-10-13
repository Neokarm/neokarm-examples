# Terraform Examples

These examples show you how to use the Terraform AWS provider with Neokarm Clusters.

> **important!** All the following examples tested using terraform v0.12 with aws provider v2.13.0

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

Create programmatic access keys:

* Log in to the cluster with the relevant user

* Generate new access keys: **Menu** > **Account Management** > **Access Keys** > **Create**

* update the aws default credentials

    ```
    aws configure set aws_access_key_id <access_key_id>
    aws configure set aws_secret_access_key <secret_access_key>
    ```
> For load balancing examples: **Ensure that the load balancer service in your cluster is initialized**

## How to use

1. Change the directory to the relvant example

2. Run `terraform init`.

3. Run `terraform apply`.

4. If required, enter the relevant variables value.