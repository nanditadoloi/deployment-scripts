# Variables
variable "vpc_cidr" {
  default = "10.4.0.0/16"
}

variable "subnet_cidr" {
  default = ["10.4.1.0/24", "10.4.2.0/24"]
}

variable "mlg4_ami" {
  default = "ami-08e5fad56cda20dac"
}

variable "control_vpc" {
  default = "vpc-0b2138195422bf89f"
}

variable "control_sg" {
  default = "sg-04d62c0f787cd9904"
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

variable "mlg4_instance_type" {
  default = "g4dn.xlarge"
}

variable "worker_volume_size" {
  description = "Root volume size for the worker nodes"
  default     = 100
}