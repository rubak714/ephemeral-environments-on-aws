# bootstrap/state_backend.tf
# I create the S3 bucket and DynamoDB table that will hold
# Terraform state for every PR environment.
#
# Why this matters:
# GitHub Actions runs on a fresh machine every time a workflow fires.
# When pr-deploy runs, it creates resources and writes a state file.
# When pr-destroy runs later, it needs that same state file to know
# what to delete. Without S3, the state file is gone and destroy fails.


# Read the current AWS account ID.
# I use this to build a unique bucket name so it never clashes
# with someone else's bucket in another AWS account.
data "aws_caller_identity" "current" {}


# -----------------------------------------------------------------
# S3 bucket for Terraform state
# -----------------------------------------------------------------

resource "aws_s3_bucket" "tfstate" {

  # Bucket names must be globally unique across all AWS accounts.
  # I include the account ID to guarantee that.
  bucket = "ephemeral-env-tfstate-${data.aws_caller_identity.current.account_id}"

  # I never want this bucket accidentally deleted.
  # If I run terraform destroy on bootstrap, this bucket stays.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "ephemeral-environments"
    Purpose = "terraform-state"
  }
}


# Enable versioning so I can recover a previous state file
# if a workflow corrupts the current one.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Block all public access. State files contain resource IDs and
# ARNs. They must never be readable by the public internet.
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Encrypt state files at rest using AES-256.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# -----------------------------------------------------------------
# DynamoDB table for state locking
# -----------------------------------------------------------------

# If two workflows run at the same time (e.g. two PRs opened at once),
# they could both try to write state simultaneously and corrupt it.
# Terraform checks this table before writing. If a lock exists, it waits.
# The lock key must be named "LockID" exactly. That is what Terraform expects.
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = "ephemeral-environments"
    Purpose = "terraform-state-lock"
  }
}
