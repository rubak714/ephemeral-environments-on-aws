# lambda.tf
# I zip handler.py automatically and deploy it as a Lambda function.
#
# In Phase 1 I zipped the file by hand, uploaded it through the console,
# and set the environment variable manually. Three separate steps.
# Here Terraform handles all three in one apply.


# -----------------------------------------------------------------
# Auto-zip
# -----------------------------------------------------------------

# archive_file reads handler.py from disk and produces handler.zip.
# I do not need to run "zip" manually. Terraform does it for me.
# It only re-zips when the source file content actually changes.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../app/handler.py"
  output_path = "${path.root}/../app/handler.zip"
}


# -----------------------------------------------------------------
# Lambda function
# -----------------------------------------------------------------

resource "aws_lambda_function" "url_shortener" {

  # I point Terraform at the zip file created above.
  filename         = data.archive_file.lambda_zip.output_path

  # This hash changes whenever handler.py changes.
  # Without it, Terraform would not re-deploy even if I updated the code.
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # I include env_name so dev and pr-123 are separate functions that never interfere.
  function_name = "url-shortener-${var.env_name}"

  # handler.py is the filename. lambda_handler is the function inside it
  # that Lambda calls on every incoming request.
  handler = "handler.lambda_handler"

  # Python 3.11 is a current, stable runtime.
  runtime = "python3.11"

  # arm64 runs on AWS Graviton. Same price as x86, roughly 20% better throughput.
  architectures = ["arm64"]

  # The role I defined in iam.tf. It permits CloudWatch Logs and DynamoDB access.
  role = aws_iam_role.lambda_exec.arn

  # I pass the table name as an environment variable.
  # handler.py reads TABLE_NAME at startup to know which DynamoDB table to use.
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.urls.name
    }
  }

  # Active tracing sends one trace per request to X-Ray.
  # X-Ray shows me exactly how long the DynamoDB call took versus the
  # Python logic, broken down per invocation. PassThrough would disable this.
  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}
