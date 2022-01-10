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
  records         = ["ns-15.zadara.net. hostmaster.zadara.net. 1 7200 900 1209600 86400"]
}

resource "aws_route53_record" "ns" {
  zone_id         = aws_route53_zone.main.zone_id
  allow_overwrite = true
  name            = aws_route53_zone.main.name
  type            = "NS"
  ttl             = "300"
  records         = ["ns.zadara.net."]
}

resource "aws_route53_record" "cluster" {
  zone_id         = aws_route53_zone.main.zone_id
  allow_overwrite = true
  name            = var.zcloud_hostname
  type            = "A"
  records         = [var.zcompute_api_ip]
  ttl             = "300"
}