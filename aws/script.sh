#!/bin/bash

sudo yum -q -y install docker git
sudo groupadd docker
sudo systemctl start docker
sudo usermod -aG docker $USER
sudo systemctl status docker
git clone -q https://github.com/Jorge-Hoyos/jenkins-training.git
sudo docker build -q -t jorge:lts jenkins-training/docker-image/
sudo docker run -p 8080:8080 -d -e MY_IP=$1 --name jorge --mount source=jenkins_data,target=/var/jenkins_home jorge:lts
