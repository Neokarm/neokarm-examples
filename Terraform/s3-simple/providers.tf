provider "aws" {
  version = "=2.13.0"
  endpoints {
    s3 = "https://${var.symphony_ip}:1060"
  }

  insecure                    = true
  s3_force_path_style         = true
  skip_metadata_api_check     = true
  skip_credentials_validation = true

  # No importance for this value currently
  region = "us-east-1"
}
