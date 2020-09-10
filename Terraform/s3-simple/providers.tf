provider "aws" {
  endpoints {
    s3 = "https://${var.symphony_ip}:1060"
  }

  insecure                    = true
  s3_force_path_style         = true
  skip_metadata_api_check     = true
  skip_credentials_validation = true
  
  # AWS plugin version
  version = "=2.31.0"

  # No importance for this value currently
  region = "us-east-1"
}
