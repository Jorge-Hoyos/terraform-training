output "jenkins-ip" {
  value = aws_eip.jenkins_eip.public_ip
}

output "rol-arn" {
  value = aws_iam_role.jenkins_role.arn
}
