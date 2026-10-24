# Required providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.69.0"
    }
  }
}

# AWS Provider and region
provider "aws" {
  region = "us-east-1"
}

