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
  name               = "ec2-full-access"
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
  name = "instance-full-access-policy-${random_uuid.random_cluster_id.id}"
  role = aws_iam_role.ec2-full-access.name
}
