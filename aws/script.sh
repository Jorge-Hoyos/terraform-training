#!/bin/bash

sudo yum -q -y install docker git
sudo groupadd docker
sudo systemctl start docker
sudo usermod -aG docker $USER
sudo systemctl status docker
echo SLACK_SECRET=$(aws ssm get-parameter --name /slack/secret --with-decryption --query Parameter.Value --output text --region us-east-1) >> env.list
echo GITHUB_PASSWORD=$(aws ssm get-parameter --name /github/password --with-decryption --query Parameter.Value --output text --region us-east-1) >> env.list
# echo MY_IP=$(aws ssm get-parameter --name /jenkins/ip --with-decryption --query Parameter.Value --output text --region us-east-1) >> env.list
echo $SLACK_SECRET
echo SLACK_DESCRIPTION="slack secret description" >> env.list
echo MY_IP=$1 >> env.list
git clone -q https://github.com/Jorge-Hoyos/jenkins-training.git
sudo docker build -q -t jorge:lts jenkins-training/docker-image/
sudo docker run -p 8080:8080 -d --env-file ./env.list --name jorge --mount source=jenkins_data,target=/var/jenkins_home jorge:lts
