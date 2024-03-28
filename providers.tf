terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
}