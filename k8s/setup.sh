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
echo 'alias eks2="kubectl config use-context eks-spoke1"' >> ~/.bashrc
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

echo "## Setting Image URI environment variable..."
IMAGE_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/whereami:latest

echo "## Deploying demo applications..."
echo "## EKS1..."
eks1
cat <<EOF > demo-app-eks1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whereami-eks1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whereami-eks1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: whereami-eks1
    spec:
      containers:
      - name: whereami-eks1
        image: ${IMAGE_URI}
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whereami-eks1-int
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internal
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  ipFamilyPolicy: SingleStack
  ipFamilies:
  - IPv4
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    app: whereami-eks1
EOF
kubectl apply -f demo-app-eks1.yaml

echo "## EKS2..."
eks2
cat <<EOF > demo-app-eks2.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whereami-eks2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whereami-eks2
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: whereami-eks2
    spec:
      containers:
      - name: whereami-eks2
        image: ${IMAGE_URI}
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whereami-eks2-int
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internal
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  ipFamilyPolicy: SingleStack
  ipFamilies:
  - IPv4
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    app: whereami-eks2
EOF
kubectl apply -f demo-app-eks2.yaml

