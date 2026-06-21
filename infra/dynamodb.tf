# ============================================================
# dynamodb.tf
# Creates the DynamoDB table that stores URL mappings.
#
# In Phase 1 this was done by clicking through the console.
# Here it is one resource block. Terraform reads it, talks
# to AWS, and the table appears. Same result, zero clicks.
# ============================================================

resource "aws_dynamodb_table" "urls" {

  # The table name includes the environment name so that
  # dev, pr-123, and pr-456 each get their own separate table.
  # They never share data with each other.
  name = "urls-${var.env_name}"

  # PAY_PER_REQUEST means there is no reserved capacity to pay for.
  # AWS charges only when a request actually hits the table.
  # Cost at idle: zero.
  billing_mode = "PAY_PER_REQUEST"

  # hash_key is the partition key. Every item in the table is
  # looked up by this key. In handler.py this is the short ID
  # (e.g. "OddhuL").
  hash_key = "id"

  # DynamoDB requires every attribute used as a key to be
  # declared here. "S" means String.
  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}
