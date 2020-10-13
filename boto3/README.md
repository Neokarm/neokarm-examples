# boto3 Examples

These examples show you how to use the boto3 module in python with Neokarm Clusters.

> **important!** All the following examples tested using python 2.7 with boto3 v1.4.7

## Important to know

In order to create a boto3 client to manage the resources in the cluster, the client must have a custom endpoint url per service.

For example:

```
# Update the cluster API DNS/IP
CLUSTER_API = '<Cluster API DNS/IP>'

# Create session client
ec2 = boto3.Session.client(
        boto3.session.Session(),
        service_name="ec2",
        region_name="symphony",
        endpoint_url="https://%s/api/v2/aws/ec2/" % CLUSTER_API,
        verify=False
        )
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

Execute the relevant file
```
python ./example.py
```
