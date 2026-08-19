variable "aws_region" {
  type        = string
  description = "AWS Region to deploy resources into"
  default     = "us-west-2"
}

variable "app_name" {
  type        = string
  description = "Name prefix for application resources"
  default     = "nixos-web-app"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the application container"
  default     = 80
}

variable "desired_count" {
  type        = number
  description = "Number of ECS task instances to run"
  default     = 2
}

variable "task_cpu" {
  type        = string
  description = "vCPU units for the Fargate task (256 = 0.25 vCPU)"
  default     = "256"
}

variable "task_memory" {
  type        = string
  description = "RAM for the Fargate task in MB"
  default     = "512"
}
