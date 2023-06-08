#!/bin/bash
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
IMAGE_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/nyancat:latest

echo "## Deploying demo applications..."
echo "## EKS1..."
eks1
cat <<EOF > demo-app-eks1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nyancat-eks1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nyancat-eks1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: nyancat-eks1
    spec:
      containers:
      - name: nyancat-eks1
        image: ${IMAGE_URI}
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nyancat-eks1-int
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
    app: nyancat-eks1
EOF
kubectl apply -f demo-app-eks1.yaml

echo "## EKS2..."
eks2
cat <<EOF > demo-app-eks2.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nyancat-eks2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nyancat-eks2
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: nyancat-eks2
    spec:
      containers:
      - name: nyancat-eks2
        image: ${IMAGE_URI}
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nyancat-eks2-int
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
    app: nyancat-eks2
EOF
kubectl apply -f demo-app-eks2.yaml

