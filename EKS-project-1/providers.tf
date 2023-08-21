terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # access_key = "AKIAT256E5R7LWX5PMHT"
  # secret_key = "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"
}
