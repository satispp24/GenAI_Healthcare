# Application Load Balancer for GenAI Healthcare POC

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name_prefix = "genai-alb-sg"
  description = "Security group for GenAI ALB"
  vpc_id      = data.aws_vpc.default.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "GenAI-ALB-SG"
  }
}

# Application Load Balancer
resource "aws_lb" "genai_alb" {
  name               = "genai-healthcare-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Name = "GenAI-Healthcare-ALB"
    Project = "GenAI-Healthcare-POC"
  }
}

# Target Group
resource "aws_lb_target_group" "genai_tg" {
  name     = "genai-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "GenAI-Frontend-TG"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "genai_tg_attachment" {
  target_group_arn = aws_lb_target_group.genai_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 80
}

# ALB Listener
resource "aws_lb_listener" "genai_listener" {
  load_balancer_arn = aws_lb.genai_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.genai_tg.arn
  }
}

# Update EC2 Security Group to allow ALB traffic
resource "aws_security_group_rule" "allow_alb_to_ec2" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.frontend_sg.id
}