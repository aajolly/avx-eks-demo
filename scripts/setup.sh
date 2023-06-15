#!/bin/bash
echo "## Setting Environment Variables..."
REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "## Updating Packages..."
sudo yum update -y
sudo yum install jq -y

echo "Uninstall AWS CLI v1..."
sudo yum remove awscli -y
pip3 uninstall awscli

echo "Install AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
source ~/.bashrc
aws --version

echo "## Installing Kubectl..."
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.4/2023-05-11/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH

echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

echo "## Setting aliases..."
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias tf=terraform' >> ~/.bashrc
echo 'alias eks1="kubectl config use-context eks-spoke1"' >> ~/.bashrc
echo 'alias eks2="kubectl config use-context eks-spoke2"' >> ~/.bashrc
source ~/.bashrc
k version