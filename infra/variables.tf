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
