resource "aws_route53_zone" "main" {
  name = "${var.zcloud_zone}."
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone" "arpa" {
  name = "in-addr.arpa."
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
  lifecycle {
    ignore_changes = [vpc]
  }
  depends_on = [aws_route53_zone.main]
}

resource "aws_route53_record" "soa_arpa" {
  zone_id         = aws_route53_zone.arpa.zone_id
  allow_overwrite = true
  name            = aws_route53_zone.arpa.name
  type            = "SOA"
  ttl             = "300"
  records         = ["ns-15.arpa.net. hostmaster.arpa.net. 1 7200 900 1209600 86400"]
}

resource "aws_route53_record" "ns_arpa" {
  zone_id         = aws_route53_zone.arpa.zone_id
  allow_overwrite = true
  name            = aws_route53_zone.arpa.name
  type            = "NS"
  ttl             = "300"
  records         = ["ns.arpa.net."]
}

resource "aws_route53_record" "soa" {
  zone_id         = aws_route53_zone.main.zone_id
  allow_overwrite = true
  name            = aws_route53_zone.main.name
  type            = "SOA"
  ttl             = "300"
  records         = ["ns-15.${aws_route53_zone.main.name}. hostmaster.${aws_route53_zone.main.name}. 1 7200 900 1209600 86400"]
}

resource "aws_route53_record" "ns" {
  zone_id         = aws_route53_zone.main.zone_id
  allow_overwrite = true
  name            = aws_route53_zone.main.name
  type            = "NS"
  ttl             = "300"
  records         = ["ns.${aws_route53_zone.main.name}."]
}

locals {
  is_api_ip         = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.zcompute_api)) ? true : false
  zcompute_api_fqdn = local.is_api_ip ? "cloud.${var.zcloud_zone}" : var.zcompute_api
}

resource "aws_route53_record" "cluster" {
  count           = local.is_api_ip ? 1 : 0
  zone_id         = aws_route53_zone.main.zone_id
  allow_overwrite = true
  name            = local.zcompute_api_fqdn
  type            = "A"
  records         = [var.zcompute_api]
  ttl             = "300"
}