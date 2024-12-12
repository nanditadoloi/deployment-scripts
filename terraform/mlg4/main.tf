# Main entry point
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

# Define all providers here in main.tf
provider "aws" {
  alias  = "ap_south_1"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

# Get available availability zones where subnets can be created
data "aws_availability_zones" "available" {
  provider  = aws.us_west_2
  state     = "available"
  exclude_names = ["us-east-1b"]
}

# VPC
resource "aws_vpc" "mlg4_vpc" {
  provider             = aws.us_west_2
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mlg4-infra-vpc"
  }
}

# Subnets
resource "aws_subnet" "mlg4_subnet" {
  provider                = aws.us_west_2
  count                   = 2
  vpc_id                  = aws_vpc.mlg4_vpc.id
  cidr_block              = element(var.subnet_cidr, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "mlg4-infra-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "mlg4_igw" {
  provider = aws.us_west_2
  vpc_id = aws_vpc.mlg4_vpc.id
  tags = {
    Name = "mlg4-infra-igw"
  }
}

# Route Table
resource "aws_route_table" "mlg4_route_table" {
  provider     = aws.us_west_2
  vpc_id = aws_vpc.mlg4_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mlg4_igw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "mlg4_rta" {
  provider       = aws.us_west_2
  count          = 2
  subnet_id      = aws_subnet.mlg4_subnet[count.index].id
  route_table_id = aws_route_table.mlg4_route_table.id
}

# Security Group
resource "aws_security_group" "mlg4_asg_sg" {
  provider         = aws.us_west_2
  vpc_id = aws_vpc.mlg4_vpc.id
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 1024
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mlg4-infra-asg-sg"
  }
}

# Allow Kubernetes control plane communication from worker nodes
resource "aws_security_group_rule" "allow_mlg4_workers_to_control_plane" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  security_group_id = var.control_sg # Control Plane Security Group

  # Allow from worker nodes' CIDR ranges (subnets in all regions)
  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Allow Flannel VXLAN (UDP port 8472)
resource "aws_security_group_rule" "allow_mlg4_workers_flannel_vxlan" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  security_group_id = var.control_sg # Control Plane Security Group

  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Allow etcd communication (TCP ports 2379-2380)
resource "aws_security_group_rule" "allow_mlg4_workers_etcd" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"
  security_group_id = var.control_sg # Control Plane Security Group

  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Allow kubelet to kubelet communication (TCP ports 10250-10255)
resource "aws_security_group_rule" "allow_mlg4_workers_kubelet_communication" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 10250
  to_port     = 10255
  protocol    = "tcp"
  security_group_id = var.control_sg # Control Plane Security Group

  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Launch Template for ASG
resource "aws_launch_template" "gpu_template" {
  provider      = aws.us_west_2
  name_prefix   = "mlg4-gpu-template-"
  image_id      = var.mlg4_ami # Replace with a PyTorch-based AMI ID for us-east-1
  instance_type = var.mlg4_instance_type
  key_name      = var.key_name
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.mlg4_asg_sg.id]
  }

  # instance_market_options {
  #   market_type = "spot"
  #   spot_options {
  #     instance_interruption_behavior = "terminate"
  #   }
  # }

  user_data = filebase64("userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "mlg4-gpu-instance"
    }
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.worker_volume_size
      volume_type = "gp3"
    }
  }

}

# Auto Scaling Group
resource "aws_autoscaling_group" "gpu_asg" {
  provider             = aws.us_west_2
  desired_capacity     = 0
  max_size             = 3
  min_size             = 0
  vpc_zone_identifier  = aws_subnet.mlg4_subnet[*].id
  launch_template {
    id      = aws_launch_template.gpu_template.id
    version = "$Latest"
  }
  tags = [
    {
      key                 = "Name"
      value               = "mlg4-gpu-asg"
      propagate_at_launch = true
    }
  ]
}

# Output
output "availability_zones" {
  value = data.aws_availability_zones.available.names[*]
}

output "vpc_id" {
  value = aws_vpc.mlg4_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.mlg4_subnet[*].id
}

output "security_group_id" {
  value = aws_security_group.mlg4_asg_sg.id
}

## PEERING
resource "aws_vpc_peering_connection" "peer_control_gpu" {
  provider         = aws.us_west_2
  vpc_id           = aws_vpc.mlg4_vpc.id
  peer_vpc_id      = var.control_vpc
  peer_region      = "ap-south-1"
  tags = {
    Name = "control-gpu-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_ap_south_1" {
  provider                   = aws.ap_south_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_control_gpu.id
  auto_accept                = true
}
resource "aws_route" "route_mlg4_to_control" {
  provider                 = aws.us_west_2
  route_table_id           = aws_route_table.mlg4_route_table.id
  destination_cidr_block   = var.control_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_gpu.id
}
resource "aws_route" "route_control_to_ml" {
  provider                 = aws.ap_south_1
  route_table_id           = var.control_route_table_id
  destination_cidr_block   = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_gpu.id
}