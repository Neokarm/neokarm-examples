provider "aws" {
  version = "=2.13.0"
  endpoints {
    ec2 = "https://${var.symphony_ip}/api/v2/aws/ec2"
  }

  insecure                    = true
  skip_metadata_api_check     = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true

  # No importance for this value currently
  region = "us-east-1"
}

