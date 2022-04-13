resource "aws_ec2_tag" "private" {
  count = length(var.primary_private_subnets_ids)

  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
  resource_id = var.primary_private_subnets_ids[count.index]
}

resource "aws_ec2_tag" "public" {
  count = length(var.primary_public_subnets_ids)

  key         = "kubernetes.io/role/elb"
  value       = "1"
  resource_id = var.primary_public_subnets_ids[count.index]
}