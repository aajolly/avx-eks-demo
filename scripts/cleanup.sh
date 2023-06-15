#!/bin/bash
echo "## Deleting demo applications..."
echo "## EKS1..."
eks1
kubectl delete -f demo-app-eks1.yaml
echo "## EKS2..."
eks2
kubectl delete -f demo-app-eks2.yaml
echo "## Deleting Images from ECR..."
aws ecr batch-delete-image --repository-name whereami --image-ids imageTag=latest
aws ecr batch-delete-image --repository-name nyancat --image-ids imageTag=latest