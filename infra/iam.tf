# iam.tf
# I create an IAM role for Lambda and a least-privilege permission policy.
#
# In Phase 1 I attached AmazonDynamoDBFullAccess, which lets Lambda do
# anything to any table in the entire account. That is too broad.
#
# Here I give Lambda only the two DynamoDB actions handler.py actually uses,
# and only on this environment's table. Nothing else is permitted.


# -----------------------------------------------------------------
# Trust policy
# -----------------------------------------------------------------

# I tell AWS that the Lambda service is allowed to assume this role.
# Without this, Lambda cannot pick up the role at all.
# Think of it as the door Lambda is allowed to walk through.
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


# -----------------------------------------------------------------
# Permission policy
# -----------------------------------------------------------------

# I define exactly what Lambda is allowed to do once it has the role.
data "aws_iam_policy_document" "lambda_permissions" {

  # Lambda needs to write its own execution logs to CloudWatch.
  # Without these three permissions, the function runs silently with nothing to debug.
  #
  #   CreateLogGroup  - creates the /aws/lambda/... group on first run
  #   CreateLogStream - creates a new stream per execution batch
  #   PutLogEvents    - writes the actual log lines
  #
  # I scope this to arn:aws:logs:*:*:* because I cannot know the log group ARN
  # before Lambda exists. That circular dependency makes tighter scoping impractical.
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # X-Ray: Lambda sends trace segments and telemetry when active tracing is on.
  # These three actions are the minimum X-Ray requires. Without them Lambda
  # silently drops trace data and the service map stays empty.
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }

  # I give Lambda only the two DynamoDB actions handler.py actually calls.
  #
  #   GetItem - the GET /{id} route reads a short URL from the table
  #   PutItem - the POST /shorten route writes a new short URL to the table
  #
  # I scope this to this environment's table ARN only, not all tables.
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]
    resources = [aws_dynamodb_table.urls.arn]
  }
}


# -----------------------------------------------------------------
# IAM role and policy attachment
# -----------------------------------------------------------------

# The role Lambda assumes at runtime.
resource "aws_iam_role" "lambda_exec" {
  name               = "url-shortener-${var.env_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# I attach the permission policy to the role above.
resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "url-shortener-${var.env_name}-permissions"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
