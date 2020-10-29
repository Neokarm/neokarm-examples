resource "aws_vpc" "test_vpc" {
  cidr_block = "172.127.0.0/16"
  enable_dns_hostnames = false
  enable_dns_support = false
}

resource "aws_subnet" "sub1" {
  cidr_block = "172.127.3.0/24"
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "subnet1_rds_test"
  }
}

resource "aws_db_subnet_group" "dbsubnet" {
  
  name = "main"
  subnet_ids = [aws_subnet.sub1.id]
   tags = {
    Name = "My DB subnet group"
  }
}

# Create db instance 1
resource "aws_db_instance" "dbinst1" {
  identifier = "dbpost1"
  instance_class = "db.m1.medium"
  allocated_storage = 10
  engine = "mysql"
  name = "db123"
  password = "dbpassword"
  username = "terraform"
  engine_version = "5.7.00"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.dbsubnet.name
}
