# dynamodb.tf
# I create the DynamoDB table that stores short ID to URL mappings.
#
# In Phase 1 I did this by clicking through the console.
# Here it is one resource block. Terraform talks to AWS and the table appears.
# Same result, zero clicks.


resource "aws_dynamodb_table" "urls" {

  # I include env_name in the table name so dev, pr-123, and pr-456
  # each get their own table and never share data.
  name = "urls-${var.env_name}"

  # PAY_PER_REQUEST means I pay only when a request actually hits the table.
  # Cost at idle: zero. No reserved capacity to pre-purchase.
  billing_mode = "PAY_PER_REQUEST"

  # hash_key is the partition key. Every lookup goes through this.
  # In handler.py this is the short ID, for example "OddhuL".
  hash_key = "id"

  # DynamoDB requires key attributes to be declared explicitly.
  # "S" means the id column holds String values.
  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}
