#!/bin/bash
echo "## Setting Environment Variables..."
REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "## Updating Packages"
sudo yum update -y

echo "## Installing Kubectl..."
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH

echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias tf=terraform' >> ~/.bashrc
source ~/.bashrc
k version

echo "## Pull Images from Docker Hub..."
docker pull aajolly/nyancat:latest
docker pull erjosito/whereami:1.3

echo "## Login to Amazon ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "## Tag Images..."
docker tag aajolly/nyancat:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/nyancat:latest
docker tag erjosito/whereami:1.3 ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/whereami:latest

echo "## Push Images to Amazon ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/nyancat:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/whereami:latest

