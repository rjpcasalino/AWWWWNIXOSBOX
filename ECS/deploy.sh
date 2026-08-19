#!/usr/bin/env bash
set -e

AWS_REGION="us-west-2"
CLUSTER_NAME="nixos-ecs-cluster"
SERVICE_NAME="nixos-web-service-medium" # Matches your app_medium.tf service

echo "🚀 Fetching ECR URL from OpenTofu..."
ECR_URL=$(tofu output -raw ecr_repository_url)

echo "📦 Fetching latest GitHub code & building minimal OCI container via Nix..."
# This step automatically runs bss build and packages the HTML
nix-build image.nix -o result
docker load < result

echo "🔑 Authenticating with AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

echo "📤 Tagging and pushing image to ECR..."
docker tag nixos-web-app-medium:latest $ECR_URL:latest
docker push $ECR_URL:latest

echo "🔄 Triggering zero-downtime ECS deployment..."
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment \
  --region $AWS_REGION > /dev/null

echo "✅ Deployment triggered successfully! ECS is rolling out your new blog content."
