#Define API Endpoints for Zadara zCompute

provider "aws" {
  version    = "= 2.13.0"
  access_key = var.access_key
  secret_key = var.secret_key
  #shared_credentials_file = var.credentials_file

  endpoints {
    ec2 = "https://${var.zCompute_ip}/api/v2/aws/ec2"
    elb = "https://${var.zCompute_ip}/api/v2/aws/elb"
    rds = "https://${var.zCompute_ip}/api/v2/aws/rds"
  }

  insecure                    = "true"
  skip_metadata_api_check     = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true

  # No importance for this value currently
  region = "us-east-2"
}
