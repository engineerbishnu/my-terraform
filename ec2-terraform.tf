terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "ec2_example" {
  ami           = "ami-09040d770ffe2224f"
  instance_type = "t2.micro"
  key_name      = "bishnu-keypair"
  tags = {
    Name = "Bishnu-ec2"
  }
}

output "public_ip" {
  value = aws_instance.ec2_example.public_ip
}

output "keypair_name" {
  value = aws_instance.ec2_example.key_name
}
