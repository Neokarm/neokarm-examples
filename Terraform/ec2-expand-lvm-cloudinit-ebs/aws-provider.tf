provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  version = "= 2.31.0"
  endpoints {
    ec2 = "https://${var.symphony_ip}/api/v2/aws/ec2"
  }

  skip_metadata_api_check = true
  skip_credentials_validation = true
  insecure                    = true
  skip_requesting_account_id  = true
  
# No importance for this value currently
    region = "us-east-2"
}