
##
### Create a simple network infrastracture with an instance
##

resource "aws_vpc" "vpc" {
  cidr_block         = "192.168.0.0/16"
  enable_dns_support = false

  tags = {
    Name      = "vpc"
    CreatedBy = "terraform"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

resource "aws_subnet" "subnet" {
  cidr_block = "192.168.10.0/24"
  vpc_id     = "${aws_vpc.vpc.id}"
  tags = {
    Name      = "subnet",
    CreatedBy = "terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance" {
  count = "${var.quantity}"

  ami                    = "${var.ami_image}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${aws_subnet.subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  tags = {
    Name      = "instance_${count.index}"
    CreatedBy = "terraform"
  }
}

resource "aws_eip" "eip" {
  count = "${var.quantity}"

  instance = "${element(aws_instance.instance.*.id, count.index)}"
  vpc      = true
}
