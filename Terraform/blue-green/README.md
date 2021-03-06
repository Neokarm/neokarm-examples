# Overview- Blue Green deployment 

In order to simulate that "Blue-Green deployment" ,we will apply Terraform twice. In first iteration, Terraform will create VPC with an Auto Scaling Group which is connected to the load balancer. The ASG spin up two instances that will show the version and the instance ID ("Blue" production). An update in the production (as changing the instances content), will led to the second iteration, and after apply, Terraform will create a new Auto Scaling Group to accommodate the changed profile, while ensuring the previous one is still connected to the load balancer until the new production (“Green” one) is live. Soon as the new Auto Scaling Group is live and healthy, Terraform will automatically remove the “Blue” Auto Scaling Group.


## Scenario key Terraform feature

```
lifecycle {
    create_before_destroy = true
  }

```


## zCompute Pre-requisite Check list

1.Ensure you have imported an Ubuntu Xenial cloud image and make this image public, grab the AMI ID and insert it into your .tfvars file.
2.Ensure your tenants project that you are deploying into has VPC mode enabled, with access keys generated (insert the access/secret keys into your .tfvars file).
3.Ensure your account admin enabled Load-balancer service.



## Getting started
1. Make sure you have the required terraform version installed.
2. Modify the `terraform.tfvars` file according to your environment.
3. Run `terraform init`.
4. Run `terraform apply`.
5. Change the content of the html page (demonstrates change in the running app) by changing "1" to "2" in webconfig file.
6. Run `terraform apply` again. 
