terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_instance" "jenkins_instance_9" {
  ami                    = var.amis[var.region]
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.jenkins_kp.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  # for_each = var.default_tags

  tags = merge(
    var.default_tags,
    {
      resource = "ec2-server",
      Name     = "Jenkins-server"
    }
  )

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ip_address.txt"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Documents/aws/keys/terraform")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -q -y install docker git",
      "sudo groupadd docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker $USER",
      "sudo systemctl status docker",
      "git clone https://github.com/Jorge-Hoyos/jenkins-training.git",
      "sudo docker build -t jorge:lts jenkins-training/docker-image/",
      "sudo docker run -p 8080:8080 -d --name jorge --mount source=jenkins_data,target=/var/jenkins_home jorge:lts"
    ]
  }
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_instance_9.id
  tags = merge(
    var.default_tags,
    {
      Name = "jenkins-eip"
    }
  )
  vpc = true
}

resource "aws_key_pair" "jenkins_kp" {
  key_name   = "jenkins-kp"
  public_key = file("~/Documents/aws/keys/terraform.pub")
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group of jenkins server"
  tags        = var.default_tags
  vpc_id      = "vpc-102ad56d"

  ingress {
    description = "SSH from my house"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip_cidr
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
  path = "/jenkins/"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_iam_role" "jenkins_role" {
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role_policy.json
  name               = "jenkins-role"
  path               = "/jenkins/"
  tags               = var.default_tags
}

resource "aws_iam_role_policy" "jenkins_role_policy" {
  name   = "jenkins-policy"
  role   = aws_iam_role.jenkins_role.id
  policy = data.aws_iam_policy_document.jenkins_policy.json
}

resource "aws_s3_bucket" "jenkins_s3_data" {
  acl    = "private"
  bucket = "jenkins-s3-data"
  tags   = var.default_tags
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "jenkins_s3_public_access_block" {
  bucket = aws_s3_bucket.jenkins_s3_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_resourcegroups_group" "jenkins_resource_group" {
  name = "jenkins-resource-group"

  resource_query {
    query = <<JSON
      {
        "ResourceTypeFilters": [
          "AWS::AllSupported"
        ],
        "TagFilters": [
          {
            "Key": "creator",
            "Values": ["terraform"]
          }
        ]
      }
    JSON
  }
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
