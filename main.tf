terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0"
    }
  }
}

provider "aws" {
  region      = var.AWS_REGION
}

terraform {
  backend "s3" {
    bucket          = "tfstate-samuelhbne"
    key             = "ecs-rolling-update/terraform.tfstate"
    region          = "us-east-1"
  }
}
