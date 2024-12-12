## PEERING CONNECTIONS
# VPC Peering between control and us-west-1
resource "aws_vpc_peering_connection" "peer_control_us_west_1" {
  provider         = aws.ap_south_1
  vpc_id           = var.control_plane_vpc
  peer_vpc_id      = aws_vpc.vpc_us_west_1.id
  peer_region      = "us-west-1"
  tags = {
    Name = "control-us-west-1-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_control_us_west_1" {
  provider                   = aws.us_west_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_control_us_west_1.id
  auto_accept                = true
}

# VPC Peering between control and us-east-1
resource "aws_vpc_peering_connection" "peer_control_us_east_1" {
  provider         = aws.ap_south_1
  vpc_id           = var.control_plane_vpc
  peer_vpc_id      = aws_vpc.vpc_us_east_1.id
  peer_region      = "us-east-1"
  tags = {
    Name = "control-us-east-1-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_control_us_east_1" {
  provider                   = aws.us_east_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_control_us_east_1.id
  auto_accept                = true
}

# VPC Peering between control and ap-south-1
resource "aws_vpc_peering_connection" "peer_control_ap_south_1" {
  provider         = aws.ap_south_1
  vpc_id           = var.control_plane_vpc
  peer_vpc_id      = aws_vpc.vpc_ap_south_1.id
  peer_region      = "ap-south-1"
  tags = {
    Name = "control-ap-south-1-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_control_ap_south_1" {
  provider                   = aws.ap_south_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_control_ap_south_1.id
  auto_accept                = true
}

## ROUTE TABLE ON CONTROL PLANE
# Route Table for control plane VPC
resource "aws_route_table" "rt_control_plane" {
  provider = aws.ap_south_1
  vpc_id   = var.control_plane_vpc
  tags = {
    Name = "control-plane-rt"
  }
}
resource "aws_route_table_association" "control_plane_association_rt" {
  provider       = aws.ap_south_1
  subnet_id      = var.control_plane_subnet
  route_table_id = aws_route_table.rt_control_plane.id
}
resource "aws_route" "route_control_plane_internet" {
  provider               = aws.ap_south_1
  route_table_id         = aws_route_table.rt_control_plane.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.control_plane_igw
}

## Additional Routes between the VPCs
# Route between Control and ap-south-1
resource "aws_route" "route_to_control_plane_from_ap_south_1" {
  provider                 = aws.ap_south_1
  route_table_id           = aws_route_table.rt_public_ap_south_1.id
  destination_cidr_block   = var.control_plane_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_ap_south_1.id
}
resource "aws_route" "route_to_ap_south_1_from_control_plane" {
  provider                 = aws.ap_south_1
  route_table_id           = aws_route_table.rt_control_plane.id
  destination_cidr_block   = aws_vpc.vpc_ap_south_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_ap_south_1.id
}

# Route between Control and us-east-1
resource "aws_route" "route_to_control_plane_from_us_east_1" {
  provider                 = aws.us_east_1
  route_table_id           = aws_route_table.rt_public_us_east_1.id
  destination_cidr_block   = var.control_plane_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_us_east_1.id
}
resource "aws_route" "route_to_us_east_1_from_control_plane" {
  provider                 = aws.ap_south_1
  route_table_id           = aws_route_table.rt_control_plane.id
  destination_cidr_block   = aws_vpc.vpc_us_east_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_us_east_1.id
}

# Route between Control and us-west-1
resource "aws_route" "route_to_control_plane_from_us_west_1" {
  provider                 = aws.us_west_1
  route_table_id           = aws_route_table.rt_public_us_west_1.id
  destination_cidr_block   = var.control_plane_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_us_west_1.id
}
resource "aws_route" "route_to_us_west_1_from_control_plane" {
  provider                 = aws.ap_south_1
  route_table_id           = aws_route_table.rt_control_plane.id
  destination_cidr_block   = aws_vpc.vpc_us_west_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_control_us_west_1.id
}

# Allow Kubernetes control plane communication from worker nodes
resource "aws_security_group_rule" "allow_worker_to_control_plane" {
  type        = "ingress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  # Allow from worker nodes' CIDR ranges (subnets in all regions)
  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

# Allow Flannel VXLAN (UDP port 8472)
resource "aws_security_group_rule" "allow_flannel_vxlan" {
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

# Allow etcd communication (TCP ports 2379-2380)
resource "aws_security_group_rule" "allow_etcd" {
  type        = "ingress"
  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

# Allow kubelet to kubelet communication (TCP ports 10250-10255)
resource "aws_security_group_rule" "allow_kubelet_communication" {
  type        = "ingress"
  from_port   = 10250
  to_port     = 10255
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    aws_subnet.subnet_ap_south_1a.cidr_block,
    aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    aws_subnet.subnet_us_east_1a.cidr_block,
    aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

## NFS security rules
resource "aws_security_group_rule" "allow_nfs_portmapper_tcp" {
  type        = "ingress"
  from_port   = 111
  to_port     = 111
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    # aws_subnet.subnet_ap_south_1a.cidr_block,
    # aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    # aws_subnet.subnet_us_east_1a.cidr_block,
    # aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

resource "aws_security_group_rule" "allow_nfs_portmapper_udp" {
  type        = "ingress"
  from_port   = 111
  to_port     = 111
  protocol    = "udp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    # aws_subnet.subnet_ap_south_1a.cidr_block,
    # aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    # aws_subnet.subnet_us_east_1a.cidr_block,
    # aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

resource "aws_security_group_rule" "allow_nfs_tcp" {
  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    # aws_subnet.subnet_ap_south_1a.cidr_block,
    # aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    # aws_subnet.subnet_us_east_1a.cidr_block,
    # aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

resource "aws_security_group_rule" "allow_nfs_udp" {
  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "udp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    # aws_subnet.subnet_ap_south_1a.cidr_block,
    # aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    # aws_subnet.subnet_us_east_1a.cidr_block,
    # aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

resource "aws_security_group_rule" "allow_nfs_mountd_tcp" {
  type        = "ingress"
  from_port   = 20048
  to_port     = 20048
  protocol    = "tcp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    # aws_subnet.subnet_ap_south_1a.cidr_block,
    # aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    # aws_subnet.subnet_us_east_1a.cidr_block,
    # aws_subnet.subnet_us_east_1b.cidr_block
  ]
}

resource "aws_security_group_rule" "allow_nfs_mountd_udp" {
  type        = "ingress"
  from_port   = 20048
  to_port     = 20048
  protocol    = "udp"
  security_group_id = "sg-04d62c0f787cd9904" # Control Plane Security Group

  cidr_blocks = [
    # aws_subnet.subnet_ap_south_1a.cidr_block,
    # aws_subnet.subnet_ap_south_1b.cidr_block,
    aws_subnet.subnet_us_west_1a.cidr_block,
    aws_subnet.subnet_us_west_1c.cidr_block,
    # aws_subnet.subnet_us_east_1a.cidr_block,
    # aws_subnet.subnet_us_east_1b.cidr_block
  ]
}