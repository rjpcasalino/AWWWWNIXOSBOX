Moving to **AWS ECS** simplifies this architecture. Instead of running full NixOS virtual machines, Nix compiles your app into a minimal OCI container image using `pkgs.dockerTools`.

This solves the `t4g.micro` memory issue: all building happens in CI or locally, and ECS only runs the compiled container on **AWS Fargate (ARM64)** or **ECS on EC2**.

---

### Architecture Overview

```
                      [ Internet (IPv6 / IPv4) ]
                                  │
                                  ▼
               ┌──────────────────────────────────────┐
               │   Application Load Balancer (ALB)    │
               │   (Dual-stack / Multi-AZ Public)     │
               └──────────────────┬───────────────────┘
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
┌──────────────────────────────┐                ┌──────────────────────────────┐
│  ECS Task (Fargate ARM64)    │                │  ECS Task (Fargate ARM64)    │
│  - Container: Nginx + WebApp │                │  - Container: Nginx + WebApp │
│  - Image Size: ~15MB (Nix)   │                │  - Image Size: ~15MB (Nix)   │
└──────────────────────────────┘                └──────────────────────────────┘

```

---

### Step 1: Containerize with Nix (`image.nix`)

Nix builds lightweight OCI images directly without needing a `Dockerfile` or running a Docker daemon. `dockerTools.buildLayeredImage` automatically splits dependencies into distinct layers for fast caching.

Create **`image.nix`**:

```nix
{ pkgs ? import <nixpkgs> { system = "aarch64-linux"; } }:

let
  # Web application static files
  site = pkgs.runCommand "web-app-content" {} ''
    mkdir -p $out
    cat << 'HTML' > $out/index.html
<!DOCTYPE html>
<html>
<head><title>NixOS on ECS</title></head>
<body style="background:#090a0f; color:#7ebae4; font-family:sans-serif; text-align:center; padding-top:10vh;">
  <h1>Nix-Built OCI Container on AWS ECS</h1>
  <p>Minimal footprint • Zero OS bloat • ARM64</p>
</body>
</html>
HTML
  '';

  # Custom Nginx configuration
  nginxConf = pkgs.writeText "nginx.conf" ''
    user nobody;
    daemon off;
    error_log /dev/stdout info;
    events { worker_connections 1024; }
    http {
      access_log /dev/stdout;
      server {
        listen 80;
        listen [::]:80;
        location / {
          root ${site};
          index index.html;
        }
      }
    }
  '';

in pkgs.dockerTools.buildLayeredImage {
  name = "nixos-web-app";
  tag = "latest";

  # Include only required binaries (Nginx, core utilities)
  contents = [ pkgs.nginx pkgs.fakeNss ];

  config = {
    Cmd = [ "nginx" "-c" "${nginxConf}" ];
    ExposedPorts = { "80/tcp" = {}; };
  };
}

```

---

### Step 2: Build & Push to AWS ECR

Build the image locally or in CI and push it to AWS ECR:

```bash
# 1. Build the ARM64 container image using Nix
nix-build image.nix -o result

# 2. Load into local Docker daemon & tag for ECR
docker load < result
docker tag nixos-web-app:latest <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/nixos-web-app:latest

# 3. Authenticate & push to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com
docker push <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/nixos-web-app:latest

```

---

### Step 3: OpenTofu ECS Infrastructure Blueprint

This OpenTofu configuration sets up an ECR repository, ECS Cluster, Fargate ARM64 Task Definition, and a dual-stack ALB.

```hcl
# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# ==============================================================================
# 1. ECR Repository
# ==============================================================================
resource "aws_ecr_repository" "app" {
  name                 = "nixos-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ==============================================================================
# 2. ECS Cluster
# ==============================================================================
resource "aws_ecs_cluster" "main" {
  name = "nixos-ecs-cluster"
}

# ==============================================================================
# 3. Task Definition (Fargate ARM64)
# ==============================================================================
resource "aws_iam_role" "ecs_execution_role" {
  name = "nixos-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "nixos-web-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "nixos-app"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# ==============================================================================
# 4. Networking & Load Balancer
# ==============================================================================
resource "aws_vpc" "ecs_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_subnet" "public_a" {
  vpc_id                          = aws_vpc.ecs_vpc.id
  cidr_block                      = "10.0.1.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.ecs_vpc.ipv6_cidr_block, 8, 1)
  availability_zone               = "us-west-2a"
  assign_ipv6_address_on_creation = true
}

resource "aws_subnet" "public_b" {
  vpc_id                          = aws_vpc.ecs_vpc.id
  cidr_block                      = "10.0.2.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.ecs_vpc.ipv6_cidr_block, 8, 2)
  availability_zone               = "us-west-2b"
  assign_ipv6_address_on_creation = true
}

resource "aws_security_group" "alb_sg" {
  name   = "ecs-alb-sg"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "nixos-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "dualstack"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name        = "nixos-ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    path = "/"
    port = "80"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ==============================================================================
# 5. ECS Service
# ==============================================================================
resource "aws_ecs_service" "app" {
  name            = "nixos-web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "nixos-app"
    container_port   = 80
  }
}

```

---

### Key Advantages of the ECS + Nix Pattern

1. **Tiny Footprint:** Nix OCI images omit systemd, kernel modules, and package managers, producing images under **20 MB**.
2. **Zero In-Cluster Build Overheads:** No RAM exhaustion or swap required on AWS tasks.
3. **ARM64 FARGATE Cost Savings:** Running ARM64 tasks on AWS Fargate is ~20% cheaper than x86_64 and eliminates EC2 instance management entirely.
