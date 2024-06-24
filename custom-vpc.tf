terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

# Define the provider
provider "aws" {
  region = "us-east-2"  # Change to your desired region
}

# Define the VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "bishnu-vpc"
  }
}

# Define an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "bishnu-igw"
  }
}

# Define a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
  tags = {
    Name = "bishnu-public-subnet"
  }
}

# Define a Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "bishnu-public-rt"
  }
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Define a Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  name   = "bishnu-web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "bishnu-web-sg"
  }
}

# Define the EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Replace with a valid AMI ID for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = "bishnu-keypair"  # Use your existing key pair name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "bishnu-ec2-vpc"
  }
}
