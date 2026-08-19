# ==============================================================================
# Application Load Balancer & Target Group
# ==============================================================================

resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
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

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# ==============================================================================
# 1. Target Group (Points to your blog container on port 80)
# ==============================================================================

resource "aws_lb_target_group" "tg_medium" {
  name        = "nixos-ecs-tg-blog"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = tostring(var.container_port)
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ==============================================================================
# 2. Port 80 Listener (HTTP -> Automatically Redirects to HTTPS)
# ==============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
    }
  }
}

# ==============================================================================
# 3. Port 443 Listener (HTTPS -> Forwards to Blog Container)
# ==============================================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_medium.arn
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]
}
