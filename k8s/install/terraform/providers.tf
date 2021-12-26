terraform {
  required_providers {
    aws = {
      version = "~> 3.0"
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  endpoints {
    ec2 = "https://${var.zcompute_api_ip}/api/v2/aws/ec2"
    elb = "https://${var.zcompute_api_ip}/api/v2/aws/elb"
    elbv2 = "https://${var.zcompute_api_ip}/api/v2/aws/elbv2"
    s3 = "https://${var.zcompute_api_ip}:1061/"
    rds = "https://${var.zcompute_api_ip}/api/v2/aws/rds"
    iam = "https://${var.zcompute_api_ip}/api/v2/aws/iam"
    route53 = "https://${var.zcompute_api_ip}/api/v2/aws/route53"
    sts = "https://${var.zcompute_api_ip}/api/v2/aws/sts"
  }
  region = "us-east-1"
  insecure = true
}