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
resource "aws_vpc" "ml_vpc" {
  provider             = aws.us_west_2
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ml-infra-vpc"
  }
}

# Subnets
resource "aws_subnet" "ml_subnet" {
  provider                = aws.us_west_2
  count                   = 2
  vpc_id                  = aws_vpc.ml_vpc.id
  cidr_block              = element(var.subnet_cidr, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "ml-infra-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ml_igw" {
  provider = aws.us_west_2
  vpc_id = aws_vpc.ml_vpc.id
  tags = {
    Name = "ml-infra-igw"
  }
}

# Route Table
resource "aws_route_table" "ml_route_table" {
  provider     = aws.us_west_2
  vpc_id = aws_vpc.ml_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ml_igw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "ml_rta" {
  provider       = aws.us_west_2
  count          = 2
  subnet_id      = aws_subnet.ml_subnet[count.index].id
  route_table_id = aws_route_table.ml_route_table.id
}

# Security Group
resource "aws_security_group" "ml_asg_sg" {
  provider         = aws.us_west_2
  vpc_id = aws_vpc.ml_vpc.id
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
    Name = "ml-infra-asg-sg"
  }
}

# Allow Kubernetes control plane communication from worker nodes
resource "aws_security_group_rule" "allow_ml_workers_to_control_plane" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  # Allow from worker nodes' CIDR ranges (subnets in all regions)
  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Allow Flannel VXLAN (UDP port 8472)
resource "aws_security_group_rule" "allow_ml_workers_flannel_vxlan" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Allow etcd communication (TCP ports 2379-2380)
resource "aws_security_group_rule" "allow_ml_workers_etcd" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Allow kubelet to kubelet communication (TCP ports 10250-10255)
resource "aws_security_group_rule" "allow_ml_workers_kubelet_communication" {
  provider    = aws.ap_south_1
  type        = "ingress"
  from_port   = 10250
  to_port     = 10255
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    var.vpc_cidr
  ]
}

# Launch Template for ASG
resource "aws_launch_template" "gpu_template" {
  provider      = aws.us_west_2
  name_prefix   = "ml-gpu-template-"
  image_id      = var.ml_ami # Replace with a PyTorch-based AMI ID for us-east-1
  instance_type = "p3.2xlarge"
  key_name      = var.key_name
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ml_asg_sg.id]
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
      Name = "ml-gpu-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "gpu_asg" {
  provider             = aws.us_west_2
  desired_capacity     = 0
  max_size             = 2
  min_size             = 0
  vpc_zone_identifier  = aws_subnet.ml_subnet[*].id
  launch_template {
    id      = aws_launch_template.gpu_template.id
    version = "$Latest"
  }
  tags = [
    {
      key                 = "Name"
      value               = "ml-gpu-asg"
      propagate_at_launch = true
    }
  ]
}

# Output
output "availability_zones" {
  value = data.aws_availability_zones.available.names[*]
}

output "vpc_id" {
  value = aws_vpc.ml_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.ml_subnet[*].id
}

output "security_group_id" {
  value = aws_security_group.ml_asg_sg.id
}

## PEERING
resource "aws_vpc_peering_connection" "peer_control_gpu" {
  provider         = aws.us_west_2
  vpc_id           = aws_vpc.ml_vpc.id
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
resource "aws_route" "route_ml_to_control" {
  provider                 = aws.us_west_2
  route_table_id           = aws_route_table.ml_route_table.id
  destination_cidr_block   = var.control_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_gpu.id
}
resource "aws_route" "route_control_to_ml" {
  provider                 = aws.ap_south_1
  route_table_id           = var.control_route_table_id
  destination_cidr_block   = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_gpu.id
}