resource "aws_ssm_association" "jenkins_stop_instance_association" {
  name                = "AWS-StopEC2Instance"
  association_name    = "stop_jenkins_instance"
  schedule_expression = "cron(0 0 23 ? * * *)"
  parameters = {
    "InstanceId"           = aws_instance.jenkins_instance.id
    "AutomationAssumeRole" = aws_iam_role.jenkins_automation_role.arn
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.jenkins_s3_data.id
    s3_key_prefix  = "automation/stop"
  }
}

resource "aws_ssm_association" "jenkins_start_instance_association" {
  name                = aws_ssm_document.jenkins_start_server.name
  association_name    = "start_jenkins_instance"
  schedule_expression = "cron(0 0 11 ? * * *)"
  parameters = {
    "InstanceId"           = aws_instance.jenkins_instance.id
    "AutomationAssumeRole" = aws_iam_role.jenkins_automation_role.arn
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.jenkins_s3_data.id
    s3_key_prefix  = "automation/start"
  }
}

resource "aws_ssm_document" "jenkins_start_docker" {
  name          = "jenkins_start_docker"
  document_type = "Command"

  content = templatefile("ssm-documents/start-docker-document.json", {})
}

resource "aws_ssm_document" "jenkins_start_server" {
  name          = "jenkins_start_server"
  document_type = "Automation"

  content = templatefile("ssm-documents/start-jenkins-server-document.json", {})
}

resource "aws_iam_role" "jenkins_automation_role" {
  assume_role_policy = data.aws_iam_policy_document.jenkins_automation_assume_role_policy.json
  name               = "jenkins-automation-role"
  path               = "/jenkins/"
  tags               = var.default_tags
}

data "aws_iam_policy_document" "jenkins_automation_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "ssm_attach" {
  name       = "ssm-policy-attachment"
  roles      = [aws_iam_role.jenkins_automation_role.name]
  policy_arn = data.aws_iam_policy.AmazonSSMAutomationRole.arn
}

data "aws_iam_policy" "AmazonSSMAutomationRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}
