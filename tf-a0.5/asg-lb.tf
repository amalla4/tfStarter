variable "region" {
  description = "variable for aws region for the instance"
  default     = "us-east-1"
}

provider "aws" {
  region = var.region
}

resource "aws_key_pair" "key_id" {
  key_name   = "key_id"
  public_key = file("~/.ssh/example.pub")
}

resource "aws_security_group" "terraform1-sg" {
  name_prefix = "terraform1-sg"
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
}

resource "aws_instance" "terraform1-instance" {
  ami           = "ami-00c39f71452c08778"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key_id.key_name

  vpc_security_group_ids = [
    aws_security_group.terraform1-sg.id,
  ]

  tags = {
    Name = "terraform1-instance"
  }
}

resource "aws_lb" "terraform1-lb" {
  name               = "terraform1-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform1-sg.id]
  subnets            = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

resource "aws_launch_configuration" "terraform1-lc" {
  name_prefix     = "terraform1-lc"
  image_id        = "ami-00c39f71452c08778"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.terraform1-sg.id]
  key_name        = aws_key_pair.key_id.key_name

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config
              EOF
}

resource "aws_autoscaling_group" "terraform1-asg" {
  name                      = "terraform1-asg"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true

  launch_configuration = aws_launch_configuration.terraform1-lc.id

  vpc_zone_identifier = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  tag {
    key                 = "Name"
    value               = "terraform1-asg"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.terraform1-tg.arn]

  metric {
    metric_name = "CPUUtilization"
    namespace   = "AWS/EC2"
    statistic   = "Average"
    unit        = "Percent"
  }

  scaling_policy {
    name                      = "scale-up"
    adjustment_type           = "ChangeInCapacity"
    estimated_instance_warmup = 120
    cooldown_seconds          = 300
    scaling_adjustment        = 1
    metric_aggregation        = "Average"
  }

  scaling_policy {
    name                      = "scale-down"
    adjustment_type           = "ChangeInCapacity"
    estimated_instance_warmup = 120
    cooldown_seconds          = 300
    scaling_adjustment        = -1
    metric_aggregation_type   = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_lb_target_group" "terraform1-tg" {
  name_prefix = "terraform1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0123456789abcdef0"
}

resource "aws_lb_listener" "terraform1-l" {
  load_balancer_arn = aws_lb.terraform1-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.terraform1-tg.arn
    type             = "forward"
  }
}
