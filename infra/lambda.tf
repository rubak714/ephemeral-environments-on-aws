# ============================================================
# lambda.tf
# Zips handler.py automatically and deploys it as a Lambda
# function.
#
# In Phase 1 I zipped handler.py by hand, uploaded it through
# the console, and set the environment variable manually.
# Here Terraform does all of that in one plan-and-apply.
# ============================================================


# --- Auto-zip the handler ---
# The archive_file data source reads handler.py from disk and
# produces a .zip file at the output_path below. Terraform
# re-zips only when the source file content changes.
# This replaces the manual "zip handler.zip handler.py" step.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../app/handler.py"
  output_path = "${path.root}/../app/handler.zip"
}


# --- Lambda function ---
resource "aws_lambda_function" "url_shortener" {

  # Where to find the code. Terraform uploads this zip to Lambda.
  filename = data.archive_file.lambda_zip.output_path

  # This hash changes whenever handler.py changes. Without it,
  # Terraform would not re-deploy Lambda even if the code changed.
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # The function name includes env_name so dev and pr-123 are
  # two separate functions that never interfere.
  function_name = "url-shortener-${var.env_name}"

  # handler.py is the filename. lambda_handler is the function
  # inside that file that Lambda calls on every invocation.
  handler = "handler.lambda_handler"

  # Python 3.11 is a recent stable runtime.
  runtime = "python3.11"

  # arm64 runs on AWS Graviton chips. Same price as x86 but
  # about 20 percent faster per dollar for most workloads.
  architectures = ["arm64"]

  # The IAM role defined in iam.tf. Gives Lambda permission
  # to write to CloudWatch Logs and read/write DynamoDB.
  role = aws_iam_role.lambda_exec.arn

  # Environment variable. handler.py reads TABLE_NAME at startup
  # to know which DynamoDB table to connect to.
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.urls.name
    }
  }

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}
