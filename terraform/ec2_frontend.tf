# EC2 Frontend Infrastructure for GenAI Healthcare POC

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group for EC2 instance
resource "aws_security_group" "frontend_sg" {
  name_prefix = "genai-frontend-sg"
  description = "Security group for GenAI frontend EC2"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
}

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_frontend_role" {
  name = "genai-frontend-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_frontend_profile" {
  name = "genai-frontend-ec2-profile"
  role = aws_iam_role.ec2_frontend_role.name
}

# User data script for EC2 setup
locals {
  user_data = base64encode(file("${path.module}/user_data.sh"))
}

# EC2 Instance
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  security_groups        = [aws_security_group.frontend_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.ec2_frontend_profile.name
  user_data_base64       = local.user_data

  tags = {
    Name = "GenAI-Frontend"
    Project = "GenAI-Healthcare-POC"
  }
}

# Note: Using ALB DNS name instead of Elastic IP for cost optimization