# Terraform Examples

These examples show you how to use the Terraform AWS provider with Neokarm Clusters.

> **important!** all the following examples wrote for terraform v0.12 with aws provider v2.13.0

## Before you begin

Create programmatic access keys:

* Log in to the cluster with the relevant user

* Generate new access keys: **Menu** > **Account Management** > **Access Keys** > **Create**

* update the aws default credentials

    ```
    aws configure set aws_access_key_id <access_key_id>
    aws configure set aws_secret_access_key <secret_access_key>
    ```
For load balancing examples: **Ensure you have enabled and initialized load balancer service in your cluster**

## How to use

1. Cahnge the directory to the relvant example

2. Run `terraform init`.

3. Run `terraform apply`.