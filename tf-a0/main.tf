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
  key_name = aws_key_pair.key_id.key_name

  vpc_security_group_ids = [
    aws_security_group.terraform1-sg.id,
  ]
  tags = {
    Name = "terraform1-instance"
  }
}