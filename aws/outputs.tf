output "jenkins-ip" {
  value = aws_instance.jenkins_instance.public_ip
}

output "rol-arn" {
  value = aws_iam_role.jenkins_role.arn
}
