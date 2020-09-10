provider "aws" {
  endpoints {
    ec2 = "https://${var.symphony_ip}/api/v2/aws/ec2"
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
