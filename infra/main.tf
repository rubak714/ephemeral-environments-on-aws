# main.tf
# Entry point. I declare the Terraform version and the two providers
# this project needs before any resource can be created.
#
# Think of providers like device drivers.
# The AWS provider is what lets Terraform talk to AWS.
# The archive provider is a helper I use in lambda.tf to zip handler.py
# automatically, so I never have to zip it by hand.


terraform {

  required_version = ">= 1.6"

  # Remote state backend.
  # I store state in S3 so GitHub Actions can read it between workflow runs.
  # The bucket and table were created by infra/bootstrap/.
  # Replace the bucket name with the value from: terraform -chdir=infra/bootstrap output state_bucket
  backend "s3" {
    bucket         = "ephemeral-env-tfstate-896725786477"
    key            = "envs/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {

    # Without the AWS provider, Terraform cannot create any AWS resource.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # I use this in lambda.tf to auto-zip handler.py before upload.
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}


# I chose eu-central-1 (Frankfurt) for EU data residency.
# The actual value comes from var.aws_region defined in variables.tf.
provider "aws" {
  region = var.aws_region
}
