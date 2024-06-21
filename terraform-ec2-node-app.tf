provider "aws" {
  region     = "us-east-2"
}
 
# Security group to allow HTTP and SSH traffic
resource "aws_security_group" "security" {
  name = "bishnuSG"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
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
}
 
resource "aws_instance" "ec2instance" {
  ami                    = "ami-09040d770ffe2224f"
  instance_type          = "t2.micro"
  key_name               = "bishnu-keypair"
  vpc_security_group_ids = [aws_security_group.security.id]
 
  tags = {
    Name = "bishnu-tf"
  }
 
  user_data = <<-EOF
              #!/bin/bash
              set -e
 
              # Update package index
              sudo apt update -y
 
              # Install Apache and Git
              sudo apt install -y apache2 git
 
              # Install Node.js and npm
              curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
              sudo apt-get install -y nodejs
 
              # Verify installation
              node -v
              npm -v
 
              # Start and enable Apache service
              sudo systemctl start apache2
              sudo systemctl enable apache2
 
              # Clone Git repository and setup application
              sudo git clone https://github.com/johnpapa/node-hello.git /var/www/html/node-hello
              sudo chown -R $USER:$USER /var/www/html/node-hello
              cd /var/www/html/node-hello
 
              # Install application dependencies
              npm install
 
              # Configure reverse proxy for Node.js application on port 3000
              sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null <<EOAPACHE
              <VirtualHost *:80>
                  ServerName example.com
 
                  ProxyRequests Off
                  ProxyPass / http://localhost:3000/
                  ProxyPassReverse / http://localhost:3000/
 
                  <Proxy *>
                      Require all granted
                  </Proxy>
              </VirtualHost>
              EOAPACHE
 
              # Enable necessary Apache modules and restart Apache to apply configuration changes
              sudo a2enmod proxy
              sudo a2enmod proxy_http
              sudo systemctl restart apache2
 
              # Start Node.js application
              npm start &
              EOF
}  