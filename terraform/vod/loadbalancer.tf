# Application Load Balancer for ap-south-1
resource "aws_lb" "app_lb_ap_south_1" {
  provider             = aws.ap_south_1
  name                 = "vod-app-lb-ap-south-1"
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.sg_ap_south_1.id]
  subnets              = [
    aws_subnet.subnet_ap_south_1a.id,   # Add subnet in ap-south-1a
    aws_subnet.subnet_ap_south_1b.id    # Add subnet in ap-south-1b
  ]

  enable_deletion_protection = false
}

# Target Group for ap-south-1
resource "aws_lb_target_group" "app_lb_target_group_ap_south_1" {
  provider             = aws.ap_south_1
  name                 = "vod-app-tg-ap-south-1"
  port                 = 30001                   # Your app's port in Kubernetes
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc_ap_south_1.id

  # Health check configuration
  health_check {
    path                = "/health"             # Your health check endpoint
    protocol            = "HTTP"
    interval            = 30                    # Health check interval (in seconds)
    timeout             = 5                     # Health check timeout (in seconds)
    healthy_threshold   = 2                     # Number of healthy responses before marked as healthy
    unhealthy_threshold = 2                     # Number of failures before marked as unhealthy
  }
}

# Load Balancer Listener for ap-south-1
resource "aws_lb_listener" "app_lb_listener_ap_south_1" {
  provider           = aws.ap_south_1
  load_balancer_arn  = aws_lb.app_lb_ap_south_1.arn
  port               = 80                      # Public-facing port of the load balancer
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_target_group_ap_south_1.arn
  }
}

# Repeat the same structure for us-west-1 and us-east-1

# Application Load Balancer for us-west-1
resource "aws_lb" "app_lb_us_west_1" {
  provider             = aws.us_west_1
  name                 = "vod-app-lb-us-west-1"
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.sg_us_west_1.id]
  subnets              = [
    aws_subnet.subnet_us_west_1a.id,    # Add subnet in us-west-1a
    aws_subnet.subnet_us_west_1c.id     # Add subnet in us-west-1c
  ]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_lb_target_group_us_west_1" {
  provider             = aws.us_west_1
  name                 = "vod-app-tg-us-west-1"
  port                 = 30002
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc_us_west_1.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_lb_listener_us_west_1" {
  provider           = aws.us_west_1
  load_balancer_arn  = aws_lb.app_lb_us_west_1.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_target_group_us_west_1.arn
  }
}

# Application Load Balancer for us-east-1
resource "aws_lb" "app_lb_us_east_1" {
  provider             = aws.us_east_1
  name                 = "vod-app-lb-us-east-1"
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.sg_us_east_1.id]
  subnets              = [
    aws_subnet.subnet_us_east_1a.id,    # Add subnet in us-east-1a
    aws_subnet.subnet_us_east_1b.id     # Add subnet in us-east-1b
  ]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_lb_target_group_us_east_1" {
  provider             = aws.us_east_1
  name                 = "vod-app-tg-us-east-1"
  port                 = 30003
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc_us_east_1.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_lb_listener_us_east_1" {
  provider           = aws.us_east_1
  load_balancer_arn  = aws_lb.app_lb_us_east_1.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_target_group_us_east_1.arn
  }
}
