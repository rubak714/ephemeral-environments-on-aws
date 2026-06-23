# bootstrap/outputs.tf
# After I run terraform apply in this folder, I copy these two
# values into my GitHub repository settings.
#
# How to add them to GitHub:
# Go to Settings > Secrets and variables > Actions > Variables (not Secrets)
# Add AWS_ROLE_ARN  = the role_arn value below
# Add AWS_REGION   = eu-central-1
#
# The workflows read these variables at runtime to know which
# role to assume and which region to deploy into.


output "role_arn" {
  description = "Paste this into GitHub Actions variable AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "state_bucket" {
  description = "S3 bucket name for Terraform state. Goes into the backend block in main.tf."
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_lock_table" {
  description = "DynamoDB table name for state locking."
  value       = aws_dynamodb_table.tfstate_lock.name
}
