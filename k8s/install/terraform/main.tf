resource "aws_key_pair" "ssh_key" {
  public_key      = file(var.ssh_public_key_file_path)
  key_name_prefix = "rke-key"
  lifecycle {
    ignore_changes = [public_key]
  }
}

locals {
  key_name         = aws_key_pair.ssh_key.key_name
  private_key_file = var.ssh_key_file_path
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2-full-access" {
  name               = "ec2-full-access-${var.environment}-${random_uuid.random_cluster_id.id}"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "ec2-fullaccess-policy" {
  role       = aws_iam_role.ec2-full-access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "acm-fullaccess-policy" {
  role       = aws_iam_role.ec2-full-access.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
}

resource "aws_iam_instance_profile" "full_ec2_access_profile" {
  name = "instance-full-access-policy-${var.environment}-${random_uuid.random_cluster_id.id}"
  role = aws_iam_role.ec2-full-access.name
}