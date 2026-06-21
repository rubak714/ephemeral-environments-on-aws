# ============================================================
# variables.tf
# Input variables for this Terraform configuration.
#
# Variables are the way Terraform accepts values from outside.
# Instead of hardcoding "dev" or "pr-123" into every resource,
# I define a variable once here and reference it everywhere.
# This is what makes one codebase deploy many isolated stacks.
# ============================================================

variable "env_name" {
  description = "Environment name. Appended to every resource name to keep stacks isolated. Examples: dev, pr-123, pr-456."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into. Defaults to eu-central-1 (Frankfurt)."
  type        = string
  default     = "eu-central-1"
}
