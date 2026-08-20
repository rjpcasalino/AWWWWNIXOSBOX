#!/usr/bin/env bash
set -e

# Usage: ./deploy.sh [micro|blog]
APP_TIER=$1
AWS_REGION="us-west-2"
CLUSTER_NAME="nixos-ecs-cluster"

if [ "$APP_TIER" == "blog" ]; then
    SERVICE_NAME="nixos-web-service-medium"
    IMAGE_FILE="image-blog.nix"
    TAG="blog-latest"
elif [ "$APP_TIER" == "micro" ]; then
    SERVICE_NAME="nixos-web-service-micro"
    IMAGE_FILE="image-micro.nix"
    TAG="micro-latest"
else
    echo "Please specify 'micro' or 'blog'"
    exit 1
fi

ECR_URL=$(tofu output -raw ecr_repository_url)

echo "📦 Building $APP_TIER container via Nix..."
nix-build $IMAGE_FILE -o result
docker load < result

# Authenticate and push using the specific tag
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
docker tag nixos-web-app-${APP_TIER}:latest $ECR_URL:$TAG
docker push $ECR_URL:$TAG

# Trigger ECS update
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $AWS_REGION > /dev/null
