# ---------------------------------------------------------------------------------------------------------------------
#     This module creates the following resources:
#          * VPC
#          * Subnet
#          * DB subnet group
#          * DB instance
#  
#     This example was tested on versions:
#     - zCompute version 5.5.3
#     - terraform 0.12.27
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "test_vpc" {
  cidr_block = "172.127.0.0/16"
  enable_dns_hostnames = false
  enable_dns_support = false
}

resource "aws_subnet" "subnet" {
  cidr_block = "172.127.3.0/24"
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "subnet1_rds_test"
  }
}

resource "aws_db_subnet_group" "db-sub-grp" {
  
  name = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet.id]
}

# Create db instance 1
resource "aws_db_instance" "database_instance" {
  identifier = "dbpost1"
  instance_class = "db.m1.medium"
  allocated_storage = 10
  engine = "mysql"
  name = "db123"
  password = "dbpassword"
  username = "terraform"
  engine_version = "5.7.00"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db-sub-grp.name
}
