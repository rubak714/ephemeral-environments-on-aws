# bootstrap/variables.tf
# Two inputs: the AWS region and your GitHub repo name.
# The repo name goes into the OIDC trust policy so only
# YOUR repo can assume the deploy role, no one else's.


variable "aws_region" {
  description = "AWS region for all bootstrap resources."
  type        = string
  default     = "eu-central-1"
}

variable "github_repo" {
  description = "GitHub repo in owner/name format. Used to scope the OIDC trust policy."
  type        = string
  default     = "rubak714/ephemeral-environments-on-aws"
}
