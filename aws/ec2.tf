terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-0c94855ba95c71c99"
  instance_type          = "t2.micro"
  key_name               = "ec2-kp"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  tags = {
    Name = "Jenkins-server"
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group of jenkins server"
  vpc_id      = "vpc-102ad56d"

  ingress {
    description = "SSH from my house"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["181.58.39.207/32"]
  }

  ingress {
    description = "Port 8080 open to the world"
    from_port   = 8080
    to_port     = 8080
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

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_iam_role" "jenkins_role" {
  name               = "jenkins-role"
  path               = "/jenkins/"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role_policy.json
}

resource "aws_iam_role_policy" "jenkins_role_policy" {
  name   = "jenkins-policy"
  role   = aws_iam_role.jenkins_role.id
  policy = data.aws_iam_policy_document.jenkins_policy.json
}

data "aws_iam_policy_document" "jenkins_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "jenkins_policy" {
  statement {
    sid       = "AdminPermissions"
    actions   = ["*"]
    resources = ["*"]
  }
}
