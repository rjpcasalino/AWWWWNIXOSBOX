output "ecr_repository_url" {
  description = "URL of the created ECR repository for pushing Nix images"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Public DNS address of the Dual-Stack ALB"
  value       = aws_lb.alb.dns_name
}

output "alb_url" {
  description = "HTTP URL to access the deployed Nix application"
  value       = "http://${aws_lb.alb.dns_name}"
}
