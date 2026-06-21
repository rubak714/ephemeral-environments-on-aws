# ============================================================
# main.tf
# Entry point for Terraform. Declares the version and
# the providers (plugins) this project needs.
#
# Think of providers like drivers. The AWS provider is the
# driver that lets Terraform talk to AWS. The archive
# provider is a helper that zips files automatically,
# so I do not have to zip handler.py by hand like Phase 1.
# ============================================================

terraform {
  # This project requires Terraform 1.6 or newer.
  required_version = ">= 1.6"

  required_providers {

    # The AWS provider. Without this, Terraform cannot create
    # any AWS resource.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # The archive provider. Used in lambda.tf to zip handler.py
    # automatically before uploading it to Lambda.
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Tell the AWS provider which region to deploy into.
# eu-central-1 is Frankfurt. Chosen for EU data residency.
provider "aws" {
  region = var.aws_region
}
