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
  region = var.region_ap_south_1
}

provider "aws" {
  alias  = "us_west_1"
  region = var.region_us_west_1
}

provider "aws" {
  alias  = "us_east_1"
  region = var.region_us_east_1
}
