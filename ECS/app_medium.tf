
# ==============================================================================
# 1. Task Definition (Emulating t4g.medium: 2 vCPU / 4 GB RAM ARM64)
# ==============================================================================

resource "aws_ecs_task_definition" "app_medium" {
  family                   = "nixos-web-app-medium"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "nixos-app-medium"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs-medium"
      }
    }
  }])
}

# ==============================================================================
# 2. ECS Service
# ==============================================================================

resource "aws_ecs_service" "app_medium" {
  name            = "nixos-web-service-medium"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_medium.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_medium.arn
    container_name   = "nixos-app-medium"
    container_port   = var.container_port
  }
}
