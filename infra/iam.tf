# ============================================================
# iam.tf
# IAM role and permissions for the Lambda function.
#
# In Phase 1, I attached AmazonDynamoDBFullAccess which gives
# Lambda permission to do anything to any DynamoDB table in
# the account. That is too broad for production.
#
# Here I write a least-privilege policy: Lambda gets only the
# two DynamoDB actions that handler.py actually uses, and only
# on the specific table this environment created. Nothing more.
# ============================================================


# --- Trust policy ---
# This tells AWS: "Lambda is allowed to assume this role."
# Without this, Lambda cannot use the role at all.
# Think of it as the door that Lambda is allowed to walk through.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


# --- Permission policy ---
# Defines what Lambda is actually allowed to DO once it has the role.
data "aws_iam_policy_document" "lambda_permissions" {

  # CloudWatch Logs: Lambda must write its own execution logs.
  # Without these three permissions, Lambda runs silently with
  # no logs to debug from.
  #   CreateLogGroup  - create the /aws/lambda/... log group on first run
  #   CreateLogStream - create a new stream for each execution batch
  #   PutLogEvents    - write the actual log lines into the stream
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    # Scoped to all log groups. Narrowing this further would require
    # knowing the log group ARN before the Lambda exists, which creates
    # a circular dependency. This is the standard accepted scope.
    resources = ["arn:aws:logs:*:*:*"]
  }

  # DynamoDB: only the two actions handler.py actually calls.
  #   GetItem - used by the GET /{id} route to look up a short URL
  #   PutItem - used by POST /shorten to store a new short URL
  # Scoped to this environment's table only, not all tables in the account.
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]
    resources = [aws_dynamodb_table.urls.arn]
  }
}


# --- IAM role ---
# The role that Lambda will assume at runtime.
resource "aws_iam_role" "lambda_exec" {
  name               = "url-shortener-${var.env_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


# --- Attach the permission policy to the role ---
resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "url-shortener-${var.env_name}-permissions"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
