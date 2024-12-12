# VPC, Subnets, and Security Groups for ap-south-1
resource "aws_vpc" "vpc_ap_south_1" {
  provider   = aws.ap_south_1
  cidr_block = var.vpc_cidr_ap_south_1
  tags = {
    Name = "ap-south-1-vpc"
  }
}

resource "aws_subnet" "subnet_ap_south_1a" {
  provider           = aws.ap_south_1
  vpc_id             = aws_vpc.vpc_ap_south_1.id
  cidr_block         = var.subnet_cidr_ap_south_1a
  availability_zone  = "ap-south-1a"
  tags = {
    Name = "ap-south-1a-subnet"
  }
}

resource "aws_subnet" "subnet_ap_south_1b" {
  provider           = aws.ap_south_1
  vpc_id             = aws_vpc.vpc_ap_south_1.id
  cidr_block         = var.subnet_cidr_ap_south_1b
  availability_zone  = "ap-south-1b"
  tags = {
    Name = "ap-south-1b-subnet"
  }
}

resource "aws_security_group" "sg_ap_south_1" {
  provider = aws.ap_south_1
  vpc_id   = aws_vpc.vpc_ap_south_1.id
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
    Name = "ap-south-1-sg"
  }
}

# VPC, Subnets, and Security Groups for us-west-1
resource "aws_vpc" "vpc_us_west_1" {
  provider   = aws.us_west_1
  cidr_block = var.vpc_cidr_us_west_1
  tags = {
    Name = "us-west-1-vpc"
  }
}

resource "aws_subnet" "subnet_us_west_1a" {
  provider           = aws.us_west_1
  vpc_id             = aws_vpc.vpc_us_west_1.id
  cidr_block         = var.subnet_cidr_us_west_1a
  availability_zone  = "us-west-1a"
  tags = {
    Name = "us-west-1a-subnet"
  }
}

resource "aws_subnet" "subnet_us_west_1c" {
  provider           = aws.us_west_1
  vpc_id             = aws_vpc.vpc_us_west_1.id
  cidr_block         = var.subnet_cidr_us_west_1c
  availability_zone  = "us-west-1c"
  tags = {
    Name = "us-west-1c-subnet"
  }
}

resource "aws_security_group" "sg_us_west_1" {
  provider = aws.us_west_1
  vpc_id   = aws_vpc.vpc_us_west_1.id
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
    Name = "us-west-1-sg"
  }
}

# VPC, Subnets, and Security Groups for us-east-1
resource "aws_vpc" "vpc_us_east_1" {
  provider   = aws.us_east_1
  cidr_block = var.vpc_cidr_us_east_1
  tags = {
    Name = "us-east-1-vpc"
  }
}

resource "aws_subnet" "subnet_us_east_1a" {
  provider           = aws.us_east_1
  vpc_id             = aws_vpc.vpc_us_east_1.id
  cidr_block         = var.subnet_cidr_us_east_1a
  availability_zone  = "us-east-1a"
  tags = {
    Name = "us-east-1a-subnet"
  }
}

resource "aws_subnet" "subnet_us_east_1b" {
  provider           = aws.us_east_1
  vpc_id             = aws_vpc.vpc_us_east_1.id
  cidr_block         = var.subnet_cidr_us_east_1b
  availability_zone  = "us-east-1b"
  tags = {
    Name = "us-east-1b-subnet"
  }
}

resource "aws_security_group" "sg_us_east_1" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.vpc_us_east_1.id
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
    Name = "us-east-1-sg"
  }
}

# Internet gateway for ELB
# VPC, Subnets, and Security Groups for ap-south-1

# Internet Gateway for ap-south-1 VPC
resource "aws_internet_gateway" "igw_ap_south_1" {
  provider = aws.ap_south_1
  vpc_id   = aws_vpc.vpc_ap_south_1.id
  tags = {
    Name = "ap-south-1-igw"
  }
}

# Public Route Table for ap-south-1 VPC (for public internet access)
resource "aws_route_table" "rt_public_ap_south_1" {
  provider = aws.ap_south_1
  vpc_id   = aws_vpc.vpc_ap_south_1.id
  tags = {
    Name = "ap-south-1-public-rt"
  }
}

# Route to Internet Gateway for public route table
resource "aws_route" "route_public_ap_south_1_internet" {
  provider               = aws.ap_south_1
  route_table_id         = aws_route_table.rt_public_ap_south_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_ap_south_1.id
}

# Associate public subnets with the public route table (public internet access)
resource "aws_route_table_association" "subnet_ap_south_1a_association_public" {
  provider       = aws.ap_south_1
  subnet_id      = aws_subnet.subnet_ap_south_1a.id
  route_table_id = aws_route_table.rt_public_ap_south_1.id
}

resource "aws_route_table_association" "subnet_ap_south_1b_association_public" {
  provider       = aws.ap_south_1
  subnet_id      = aws_subnet.subnet_ap_south_1b.id
  route_table_id = aws_route_table.rt_public_ap_south_1.id
}

# VPC, Subnets, and Security Groups for us-west-1

# Internet Gateway for us-west-1 VPC
resource "aws_internet_gateway" "igw_us_west_1" {
  provider = aws.us_west_1
  vpc_id   = aws_vpc.vpc_us_west_1.id
  tags = {
    Name = "us-west-1-igw"
  }
}

# Public Route Table for us-west-1 VPC (for public internet access)
resource "aws_route_table" "rt_public_us_west_1" {
  provider = aws.us_west_1
  vpc_id   = aws_vpc.vpc_us_west_1.id
  tags = {
    Name = "us-west-1-public-rt"
  }
}

# Route to Internet Gateway for public route table
resource "aws_route" "route_public_us_west_1_internet" {
  provider               = aws.us_west_1
  route_table_id         = aws_route_table.rt_public_us_west_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_us_west_1.id
}

# Associate public subnets with the public route table (public internet access)
resource "aws_route_table_association" "subnet_us_west_1a_association_public" {
  provider       = aws.us_west_1
  subnet_id      = aws_subnet.subnet_us_west_1a.id
  route_table_id = aws_route_table.rt_public_us_west_1.id
}

resource "aws_route_table_association" "subnet_us_west_1c_association_public" {
  provider       = aws.us_west_1
  subnet_id      = aws_subnet.subnet_us_west_1c.id
  route_table_id = aws_route_table.rt_public_us_west_1.id
}

# VPC, Subnets, and Security Groups for us-east-1

# Internet Gateway for us-east-1 VPC
resource "aws_internet_gateway" "igw_us_east_1" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.vpc_us_east_1.id
  tags = {
    Name = "us-east-1-igw"
  }
}

# Public Route Table for us-east-1 VPC (for public internet access)
resource "aws_route_table" "rt_public_us_east_1" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.vpc_us_east_1.id
  tags = {
    Name = "us-east-1-public-rt"
  }
}

# Route to Internet Gateway for public route table
resource "aws_route" "route_public_us_east_1_internet" {
  provider               = aws.us_east_1
  route_table_id         = aws_route_table.rt_public_us_east_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_us_east_1.id
}

# Associate public subnets with the public route table (public internet access)
resource "aws_route_table_association" "subnet_us_east_1a_association_public" {
  provider       = aws.us_east_1
  subnet_id      = aws_subnet.subnet_us_east_1a.id
  route_table_id = aws_route_table.rt_public_us_east_1.id
}

resource "aws_route_table_association" "subnet_us_east_1b_association_public" {
  provider       = aws.us_east_1
  subnet_id      = aws_subnet.subnet_us_east_1b.id
  route_table_id = aws_route_table.rt_public_us_east_1.id
}