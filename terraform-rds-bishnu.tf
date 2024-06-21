# configured aws provider with proper credentials
provider "aws" {
  region = "us-east-2"
}
 
# create default vpc if one does not exist
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}
 
# use data source to get all availability zones in the region
data "aws_availability_zones" "available_zones" {}
 
# create a default subnet in the first available zone
resource "aws_default_subnet" "subnet_az" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]  # First AZ in the list
}
 
# create a default subnet in the second available zone
resource "aws_default_subnet" "subnet_az2" {
availability_zone = data.aws_availability_zones.available_zones.names[1]  # Second AZ in the list
}
 
# create security group for the web server
resource "aws_security_group" "BishnuThapa" {
  name        = "BishnuThapa"
  description = "enable http access on port 80"
  vpc_id      = aws_default_vpc.default_vpc.id
 
  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "Bishnu Thapa webserver security group"
  }
}
 
# create security group for the database
resource "aws_security_group" "bishnusg" {
  name        = "bishnusg"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = aws_default_vpc.default_vpc.id
 
  ingress {
    description      = "mysql/aurora access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.BishnuThapa.id]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "Bishnu Thapa database security group"
  }
}
 
# create the subnet group for the rds instance
resource "aws_db_subnet_group" "bishnu-database01" {
  name        = "bishnu-database01"
  subnet_ids  = [aws_default_subnet.subnet_az.id, aws_default_subnet.subnet_az2.id]
 
  description = "Subnet group for Bishnu's RDS"
 
  tags = {
    Name = "Bishnu-DB database subnet group"
  }
}
 
# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                = "mysql"
  engine_version        = "5.7"
  multi_az              = false
  identifier            = "bishnudb01"
  username              = "dbbishnu"
  password              = "dbbishnu122"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  db_subnet_group_name  = aws_db_subnet_group.bishnu-database01.name
  vpc_security_group_ids = [aws_security_group.bishnusg.id]
  availability_zone     = data.aws_availability_zones.available_zones.names[0]
  publicly_accessible = true
  db_name               = "bishnuthdb"
  skip_final_snapshot   = true
}