#!/bin/bash
REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "## Updating Packages"
sudo yum update -y
# sudo amazon-linux-extras install docker -y

echo "Pull Images"
docker pull aajolly/nyancat:latest
docker pull erjosito/whereami:1.3

echo "## Login to ECR"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "## Tag Images"
docker tag aajolly/nyancat:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/nyancat:latest
docker tag erjosito/whereami:1.3 ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/whereami:latest

echo "## Push Images"
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/nyancat:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/whereami:latest