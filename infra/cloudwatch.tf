# cloudwatch.tf
# I add three observability resources here:
#   1. A CloudWatch log group with a retention policy
#   2. Two alarms: one for Lambda errors, one for slow responses
#   3. A dashboard that shows both metrics on one screen
#
# Why CloudWatch over Datadog or Prometheus?
# CloudWatch is built into every AWS account with no extra setup.
# Datadog is more powerful but costs money and adds a vendor dependency.
# Prometheus needs a server to run. For a serverless portfolio project,
# CloudWatch is the right choice: native, free-tier covered, zero extra infra.
#
# Cost:
#   Log group  - near-zero (well inside the 5 GB/month free tier)
#   Alarms (2) - free (AWS gives 10 standard alarms free per month)
#   Dashboard  - $3/month (the only resource here with an idle cost)


# -----------------------------------------------------------------
# Log group
# -----------------------------------------------------------------

# I create the log group explicitly so I can set a retention period.
# Without this block, Lambda creates the group automatically but
# keeps logs forever, which adds unnecessary storage cost over time.
# 14 days covers any realistic debugging window for an ephemeral environment.
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/url-shortener-${var.env_name}"
  retention_in_days = 14

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}


# -----------------------------------------------------------------
# Alarm: Lambda errors
# -----------------------------------------------------------------

# This alarm fires if Lambda returns any errors in a 60-second window.
# "Errors" means the function threw an unhandled exception, not a 404 or 400.
# Those are handled responses and do not count here.
#
# In a real system I would connect this to an SNS topic that emails me.
# For this portfolio the alarm exists to demonstrate the pattern.
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "url-shortener-${var.env_name}-errors"
  alarm_description   = "Lambda function returned an unhandled error."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.url_shortener.function_name
  }

  # Sum of errors across the evaluation period.
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1

  # Any single error in 60 seconds triggers the alarm.
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}


# -----------------------------------------------------------------
# Alarm: Lambda duration p99
# -----------------------------------------------------------------

# This alarm fires if the slowest 1% of requests exceed 2000ms.
# p99 is a better signal than average because averages hide outliers.
# A function that responds in 100ms 99 times but 5000ms once will
# show a low average but a high p99.
resource "aws_cloudwatch_metric_alarm" "lambda_duration_p99" {
  alarm_name          = "url-shortener-${var.env_name}-duration-p99"
  alarm_description   = "p99 Lambda duration exceeded 2000ms."
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  dimensions = {
    FunctionName = aws_lambda_function.url_shortener.function_name
  }

  extended_statistic  = "p99"
  period              = 60
  evaluation_periods  = 1
  threshold           = 2000
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  tags = {
    Environment = var.env_name
    Project     = "ephemeral-environments"
  }
}


# -----------------------------------------------------------------
# Dashboard
# -----------------------------------------------------------------

# One screen showing the four signals I care about:
# errors, duration p99, invocation count, and DynamoDB consumed write units.
# The body is JSON that CloudWatch renders as a visual dashboard.
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "url-shortener-${var.env_name}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda errors"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [[
            "AWS/Lambda", "Errors",
            "FunctionName", aws_lambda_function.url_shortener.function_name
          ]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda duration p99 (ms)"
          view   = "timeSeries"
          period = 60
          stat   = "p99"
          metrics = [[
            "AWS/Lambda", "Duration",
            "FunctionName", aws_lambda_function.url_shortener.function_name
          ]]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Lambda invocations"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [[
            "AWS/Lambda", "Invocations",
            "FunctionName", aws_lambda_function.url_shortener.function_name
          ]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB consumed write capacity"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [[
            "AWS/DynamoDB", "ConsumedWriteCapacityUnits",
            "TableName", aws_dynamodb_table.urls.name
          ]]
        }
      }
    ]
  })
}
