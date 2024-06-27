terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "bishnu-keypair"
}

resource "aws_security_group" "allow_rdp" {
  name        = "allow_rdp"
  description = "Allow RDP traffic"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow RDP traffic from anywhere"

  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"

  }
  ingress {
    from_port   = 5041
    to_port     = 5041
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow custom web traffic from anywhere"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow All traffic from anywhere"

  }
}

resource "aws_instance" "windows_server" {
  ami           = "ami-08b66c1b6d6a8a30a" # Update with the latest Windows Server AMI ID for your region
  instance_type = "t2.micro"

  key_name = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.allow_rdp.id]

  user_data = <<-EOF
<powershell>
    # Step 1: Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools

    # Step 2: Install .NET SDK
    Set-Location -Path "C:\\Users\\Administrator\\Downloads"
    Invoke-WebRequest -Uri "https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.ps1" -OutFile ".\\dotnet-install.ps1"
    .\\dotnet-install.ps1 -Channel LTS -Version 6.0.301 -InstallDir "C:\\Program Files\\dotnet" -NoPath
    $env:Path += ";C:\\Program Files\\dotnet"
    [System.Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::Machine)

    # Step 3: Download and Install Git
    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.1/Git-2.41.0-64-bit.exe" -OutFile "C:\\Users\\Administrator\\Downloads\\Git-2.41.0-64-bit.exe"
    Start-Process -FilePath "C:\\Users\\Administrator\\Downloads\\Git-2.41.0-64-bit.exe" -ArgumentList "/SILENT" -NoNewWindow -Wait
    $gitPath = "C:\\Program Files\\Git\\bin"
    $env:Path += ";$gitPath"
    [System.Environment]::SetEnvironmentVariable('Path', $env:Path + ";$gitPath", [System.EnvironmentVariableTarget]::Machine)

    # Step 4: Clone the repository
    git clone https://github.com/engineerbishnu/WebApplication1.git C:\\inetpub\\wwwroot\\WebApplication1

    # Step 5: Publish the .NET application
    cd C:\\inetpub\\wwwroot\\dotnet-webapplication1\\WebApplication1
    dotnet publish -c Release -o C:\\inetpub\\wwwroot\\WebApplication1\\publish

    # Step 6: Create and configure IIS website
    Import-Module WebAdministration

    # Remove the default website if exists
    Remove-Website -Name "Default Web Site" -ErrorAction SilentlyContinue

    # Create a new website
    New-Website -Name "WebApplication1" -PhysicalPath "C:\\inetpub\\wwwroot\\WebApplication1\\publish" -Port 80 -Force

    # Set the application pool to use No Managed Code
    Set-ItemProperty "IIS:\\Sites\\WebApplication1" -Name applicationPool -Value "No Managed Code"

    # Start the website
    Start-Website -Name "WebApplication1"

    # Step 7: Verify the website is running
    Write-Host "The .NET application has been published and is running at http://localhost"

    # Open the default browser to the site (optional)
    Start-Process "http://localhost"
</powershell>
  EOF

  tags = {
    Name = "bishnu-IIS-server"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high_cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    InstanceId = aws_instance.windows_server.id
  }

  alarm_actions = [
    "arn:aws:sns:us-east-2:123456789012:my_sns_topic" # Update with your SNS topic ARN
  ]

  tags = {
    Name = "high_cpu_alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low_cpu_utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    InstanceId = aws_instance.windows_server.id
  }

  alarm_actions = [
    "arn:aws:sns:us-east-2:123456789012:my_sns_topic" # Update with your SNS topic ARN
  ]

  tags = {
    Name = "low_cpu_alarm"
  }
}
