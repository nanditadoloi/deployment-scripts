# Variables
variable "vpc_cidr" {
  default = "10.3.0.0/16"
}

variable "subnet_cidr" {
  default = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "ml_ami" {
  default = "ami-09918a3bc64be1cd8"
}

variable "control_vpc" {
  default = "vpc-0b2138195422bf89f"
}

variable "control_cidr" {
  default = "172.31.0.0/16"
}

variable "control_route_table_id" {
  default = "rtb-08651aebee91c4b29"
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "nandita_aws"
}