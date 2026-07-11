# variables.tf
# I define input variables here so I never hardcode environment names
# or regions inside individual resource files.
#
# The key idea: I pass env_name=pr-123 at deploy time and every
# resource in this stack gets that value in its name automatically.
# That is what keeps dev, pr-123, and pr-456 fully isolated.


# I append this to every resource name.
# dev is the default for local work. GitHub Actions passes pr-<number> for each PR.
variable "env_name" {
  description = "Environment name appended to every resource. Examples: dev, pr-123, pr-456."
  type        = string
  default     = "dev"
}


# I default to Frankfurt for EU data residency.
# I can override this per-environment if needed.
variable "aws_region" {
  description = "AWS region to deploy into. Defaults to eu-central-1 (Frankfurt)."
  type        = string
  default     = "eu-central-1"
}


# Lambda memory controls both RAM and vCPU allocation.
# More memory = more CPU = faster execution = higher per-ms cost.
# 256 MB is the sweet spot for Python with boto3: cold starts are
# noticeably faster than 128 MB, and the cost difference at this
# traffic level is a fraction of a cent per month.
#
# I expose this as a variable so the load test in Phase 5 can sweep
# different values (128, 256, 512) by re-applying with -var rather
# than editing the Terraform source.
variable "lambda_memory_mb" {
  description = "Lambda memory in MB. Controls both RAM and vCPU. Valid range: 128-10240."
  type        = number
  default     = 256
}
