# Launch Template for ap-south-1
resource "aws_launch_template" "worker_template_ap_south_1" {
  provider      = aws.ap_south_1
  name_prefix   = "worker-template-ap-south-1"
  instance_type = var.instance_type
  image_id      = var.ami_ap_south_1
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_ap_south_1.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.worker_volume_size
      volume_type = "gp3"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = filebase64(var.user_data_path)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k8s-worker-ap-south-1"
    }
  }
}

# Auto Scaling Group for ap-south-1
resource "aws_autoscaling_group" "worker_asg_ap_south_1" {
  provider            = aws.ap_south_1
  desired_capacity    = 0
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = [aws_subnet.subnet_ap_south_1a.id, aws_subnet.subnet_ap_south_1b.id]

  launch_template {
    id      = aws_launch_template.worker_template_ap_south_1.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_lb_target_group_ap_south_1.arn]

  tag {
    key                 = "kubernetes.io/cluster/ap-south-1-asg"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for us-west-1
resource "aws_launch_template" "worker_template_us_west_1" {
  provider      = aws.us_west_1
  name_prefix   = "worker-template-us-west-1"
  instance_type = var.instance_type
  image_id      = var.ami_us_west_1
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_us_west_1.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.worker_volume_size
      volume_type = "gp3"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = filebase64(var.user_data_path)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k8s-worker-us-west-1"
    }
  }
}

# Auto Scaling Group for us-west-1
resource "aws_autoscaling_group" "worker_asg_us_west_1" {
  provider            = aws.us_west_1
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.subnet_us_west_1a.id, aws_subnet.subnet_us_west_1c.id]

  launch_template {
    id      = aws_launch_template.worker_template_us_west_1.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_lb_target_group_us_west_1.arn]

  tag {
    key                 = "kubernetes.io/cluster/us-west-1-asg"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for us-east-1
resource "aws_launch_template" "worker_template_us_east_1" {
  provider      = aws.us_east_1
  name_prefix   = "worker-template-us-east-1"
  instance_type = var.instance_type
  image_id      = var.ami_us_east_1
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_us_east_1.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.worker_volume_size
      volume_type = "gp3"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = filebase64(var.user_data_path)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k8s-worker-us-east-1"
    }
  }
}

# Auto Scaling Group for us-east-1
resource "aws_autoscaling_group" "worker_asg_us_east_1" {
  provider            = aws.us_east_1
  desired_capacity    = 0
  max_size            = 3
  min_size            = 0
  vpc_zone_identifier = [aws_subnet.subnet_us_east_1a.id, aws_subnet.subnet_us_east_1b.id]

  launch_template {
    id      = aws_launch_template.worker_template_us_east_1.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_lb_target_group_us_east_1.arn]

  tag {
    key                 = "kubernetes.io/cluster/us-east-1-asg"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules for ap-south-1
resource "aws_security_group_rule" "allow_worker_outbound_to_control_plane_ap_south_1" {
  provider    = aws.ap_south_1
  type        = "egress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  security_group_id = aws_security_group.sg_ap_south_1.id
  cidr_blocks       = ["10.0.0.0/16"]
}

# Flannel VXLAN for ap-south-1
resource "aws_security_group_rule" "allow_flannel_vxlan_ap_south_1" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  security_group_id = aws_security_group.sg_ap_south_1.id

  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

# Security Group Rules for us-west-1
resource "aws_security_group_rule" "allow_worker_outbound_to_control_plane_us_west_1" {
  provider    = aws.us_west_1
  type        = "egress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  security_group_id = aws_security_group.sg_us_west_1.id
  cidr_blocks       = ["10.0.0.0/16"]
}

# Flannel VXLAN for us-west-1
resource "aws_security_group_rule" "allow_flannel_vxlan_us_west_1" {
  provider    = aws.us_west_1
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  security_group_id = aws_security_group.sg_us_west_1.id

  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

# Security Group Rules for us-east-1
resource "aws_security_group_rule" "allow_worker_outbound_to_control_plane_us_east_1" {
  provider    = aws.us_east_1
  type        = "egress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  security_group_id = aws_security_group.sg_us_east_1.id
  cidr_blocks       = ["10.0.0.0/16"]
}

# Flannel VXLAN for us-east-1
resource "aws_security_group_rule" "allow_flannel_vxlan_us_east_1" {
  provider    = aws.us_east_1
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  security_group_id = aws_security_group.sg_us_east_1.id

  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

# ICMP (Ping) for us-east-1
resource "aws_security_group_rule" "allow_icmp_from_us_west_1_in_us_east_1" {
  provider              = aws.us_east_1
  type                  = "ingress"
  from_port             = -1
  to_port               = -1
  protocol              = "icmp"
  security_group_id     = aws_security_group.sg_us_east_1.id
  cidr_blocks           = [var.vpc_cidr_us_west_1, var.vpc_cidr_ap_south_1]
}

# ICMP (Ping) for us-west-1
resource "aws_security_group_rule" "allow_icmp_from_us_east_1_in_us_west_1" {
  provider              = aws.us_west_1
  type                  = "ingress"
  from_port             = -1
  to_port               = -1
  protocol              = "icmp"
  security_group_id     = aws_security_group.sg_us_west_1.id
  cidr_blocks           = [var.vpc_cidr_us_east_1, var.vpc_cidr_ap_south_1]
}

# ICMP (Ping) for ap-south-1
resource "aws_security_group_rule" "allow_icmp_from_us_east_1_and_us_west_1_in_ap_south_1" {
  provider              = aws.ap_south_1
  type                  = "ingress"
  from_port             = -1
  to_port               = -1
  protocol              = "icmp"
  security_group_id     = aws_security_group.sg_ap_south_1.id
  cidr_blocks           = [var.vpc_cidr_us_east_1, var.vpc_cidr_us_west_1]
}