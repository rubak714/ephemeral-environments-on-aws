# api_gateway.tf
# I create the HTTP API that receives requests from the public internet
# and forwards them to Lambda.
#
# In Phase 1 I built this across seven console screens:
# create API, integration, two routes, stage, auto-deploy toggle, Lambda permission.
# Here it is six resource blocks.


# -----------------------------------------------------------------
# The API
# -----------------------------------------------------------------

# I use the HTTP API (v2), not the older REST API (v1).
# HTTP API is simpler and charges per request only. No hourly fee.
resource "aws_apigatewayv2_api" "http_api" {
  name          = "url-shortener-${var.env_name}"
  protocol_type = "HTTP"
}


# -----------------------------------------------------------------
# Default stage
# -----------------------------------------------------------------

# A stage is a deployment slot. "$default" means no path prefix in the URL.
# auto_deploy = true means every apply goes live immediately.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}


# -----------------------------------------------------------------
# Integration
# -----------------------------------------------------------------

# I wire the API to Lambda using AWS_PROXY mode.
# This passes the full HTTP request to Lambda as-is and returns
# Lambda's response directly. Nothing is transformed in the middle.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.url_shortener.invoke_arn
  payload_format_version = "2.0"
}


# -----------------------------------------------------------------
# Routes
# -----------------------------------------------------------------

# POST /shorten: I use this to create a new short URL.
resource "aws_apigatewayv2_route" "post_shorten" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# GET /{id}: I use this to look up a short ID and get a 301 redirect.
# {id} is a path parameter. handler.py reads it from the request.
resource "aws_apigatewayv2_route" "get_redirect" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}


# -----------------------------------------------------------------
# Lambda invoke permission
# -----------------------------------------------------------------

# I explicitly grant API Gateway the right to invoke this Lambda function.
# Without this, every request returns a 500 because Lambda refuses to run.
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
