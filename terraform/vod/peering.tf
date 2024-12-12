## PEERING CONNECTIONS
# VPC Peering between ap-south-1 and us-west-1
resource "aws_vpc_peering_connection" "peer_ap_south_1_us_west_1" {
  provider         = aws.ap_south_1
  vpc_id           = aws_vpc.vpc_ap_south_1.id
  peer_vpc_id      = aws_vpc.vpc_us_west_1.id
  peer_region      = "us-west-1"
  tags = {
    Name = "ap-south-1-us-west-1-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_ap_south_1_us_west_1" {
  provider                   = aws.us_west_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_ap_south_1_us_west_1.id
  auto_accept                = true
}

# VPC Peering between ap-south-1 and us-east-1
resource "aws_vpc_peering_connection" "peer_ap_south_1_us_east_1" {
  provider         = aws.ap_south_1
  vpc_id           = aws_vpc.vpc_ap_south_1.id
  peer_vpc_id      = aws_vpc.vpc_us_east_1.id
  peer_region      = "us-east-1"
  tags = {
    Name = "ap-south-1-us-east-1-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_ap_south_1_us_east_1" {
  provider                   = aws.us_east_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_ap_south_1_us_east_1.id
  auto_accept                = true
}

# VPC Peering between us-west-1 and us-east-1
resource "aws_vpc_peering_connection" "peer_us_west_1_us_east_1" {
  provider         = aws.us_west_1
  vpc_id           = aws_vpc.vpc_us_west_1.id
  peer_vpc_id      = aws_vpc.vpc_us_east_1.id
  peer_region      = "us-east-1"
  tags = {
    Name = "us-west-1-us-east-1-peer"
  }
}
resource "aws_vpc_peering_connection_accepter" "accepter_us_west_1_us_east_1" {
  provider                   = aws.us_east_1
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_us_west_1_us_east_1.id
  auto_accept                = true
}

## ROUTES
# Routes from ap-south-1
resource "aws_route" "route_to_us_west_1_from_ap_south_1" {
  provider                 = aws.ap_south_1
  route_table_id           = aws_route_table.rt_public_ap_south_1.id
  destination_cidr_block   = aws_vpc.vpc_us_west_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_ap_south_1_us_west_1.id
}
resource "aws_route" "route_to_us_east_1_from_ap_south_1" {
  provider                 = aws.ap_south_1
  route_table_id           = aws_route_table.rt_public_ap_south_1.id
  destination_cidr_block   = aws_vpc.vpc_us_east_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_ap_south_1_us_east_1.id
}

# Routes from us-west-1
resource "aws_route" "route_to_ap_south_1_from_us_west_1" {
  provider                 = aws.us_west_1
  route_table_id           = aws_route_table.rt_public_us_west_1.id
  destination_cidr_block   = aws_vpc.vpc_ap_south_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_ap_south_1_us_west_1.id
}
resource "aws_route" "route_to_us_east_1_from_us_west_1" {
  provider                 = aws.us_west_1
  route_table_id           = aws_route_table.rt_public_us_west_1.id
  destination_cidr_block   = aws_vpc.vpc_us_east_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_us_west_1_us_east_1.id
}

# Routes from us-east-1
resource "aws_route" "route_to_ap_south_1_from_us_east_1" {
  provider                 = aws.us_east_1
  route_table_id           = aws_route_table.rt_public_us_east_1.id
  destination_cidr_block   = aws_vpc.vpc_ap_south_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_ap_south_1_us_east_1.id
}
resource "aws_route" "route_to_us_west_1_from_us_east_1" {
  provider                 = aws.us_east_1
  route_table_id           = aws_route_table.rt_public_us_east_1.id
  destination_cidr_block   = aws_vpc.vpc_us_west_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_us_west_1_us_east_1.id
}