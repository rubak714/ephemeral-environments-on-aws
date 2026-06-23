# bootstrap/main.tf
# I run this folder exactly once to set up the shared infrastructure
# that the CI/CD pipeline depends on.
#
# What lives here:
#   - S3 bucket        stores Terraform state between GitHub Actions runs
#   - DynamoDB table   prevents two workflows from applying at the same time
#   - OIDC provider    lets GitHub prove its identity to AWS without a password
#   - IAM role         what GitHub Actions actually assumes to deploy resources
#
# I never run terraform destroy on this folder.
# These resources need to outlive every PR environment.


terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
