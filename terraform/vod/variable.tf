# Variables for region, VPC, subnets, and general configuration

variable "region_ap_south_1" {
  description = "Region for ap-south-1"
  default     = "ap-south-1"
}

variable "region_us_west_1" {
  description = "Region for us-west-1"
  default     = "us-west-1"
}

variable "region_us_east_1" {
  description = "Region for us-east-1"
  default     = "us-east-1"
}

variable "control_plane_vpc" {
  description = "VPC ID of the control plane"
  default     = "vpc-0b2138195422bf89f"
}

variable "control_plane_subnet" {
  description = "Subnet ID of the control plane"
  default     = "subnet-045e1cb02633b9a03"
}

variable "control_plane_cidr" {
  description = "CIDR of the control plane VPC"
  default     = "172.31.0.0/16"
}

variable "control_plane_igw" {
  description = "Internet Gateway for control plane VPC"
  default     = "igw-0e40b38b15a27ca46"
}

variable "vpc_cidr_ap_south_1" {
  description = "CIDR block for VPC in ap-south-1"
  default     = "10.0.0.0/16"
}

variable "vpc_cidr_us_west_1" {
  description = "CIDR block for VPC in us-west-1"
  default     = "10.1.0.0/16"
}

variable "vpc_cidr_us_east_1" {
  description = "CIDR block for VPC in us-east-1"
  default     = "10.2.0.0/16"
}

# New CIDR blocks for subnets that avoid conflicts
variable "subnet_cidr_ap_south_1a" {
  description = "CIDR block for ap-south-1a"
  default     = "10.0.3.0/24"
}

variable "subnet_cidr_ap_south_1b" {
  description = "CIDR block for ap-south-1b"
  default     = "10.0.4.0/24"
}

variable "subnet_cidr_us_west_1a" {
  description = "CIDR block for us-west-1a"
  default     = "10.1.3.0/24"
}

variable "subnet_cidr_us_west_1c" {
  description = "CIDR block for us-west-1c"
  default     = "10.1.4.0/24"
}

variable "subnet_cidr_us_east_1a" {
  description = "CIDR block for us-east-1a"
  default     = "10.2.3.0/24"
}

variable "subnet_cidr_us_east_1b" {
  description = "CIDR block for us-east-1b"
  default     = "10.2.4.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for workers"
  default     = "t3a.xlarge"
}

variable "ami_ap_south_1" {
  description = "AMI ID for ap-south-1"
  default     = "ami-0c5cdba2323106e82"
}

variable "ami_us_west_1" {
  description = "AMI ID for us-west-1"
  default     = "ami-004b78e6ca116ed00"
}

variable "ami_us_east_1" {
  description = "AMI ID for us-east-1"
  default     = "ami-0d04a8cac1dc3fec8"
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "nandita_aws"
}

variable "user_data_path" {
  description = "Path to the user data script"
  default     = "userdata.sh"
}

variable "worker_volume_size" {
  description = "Root volume size for the worker nodes"
  default     = 50
}
