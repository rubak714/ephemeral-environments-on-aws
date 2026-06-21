# ============================================================
# api_gateway.tf
# HTTP API that receives requests and forwards them to Lambda.
#
# In Phase 1 I built this through seven console screens:
# create API, create integration, create routes, create stage,
# enable auto-deploy, and attach Lambda permission.
# Here it is six resource blocks.
# ============================================================


# --- The API itself ---
# aws_apigatewayv2_api is the HTTP API (v2). It is simpler and
# cheaper than the older REST API (v1). HTTP API charges only
# per request with no hourly fee.
resource "aws_apigatewayv2_api" "http_api" {
  name          = "url-shortener-${var.env_name}"
  protocol_type = "HTTP"
}


# --- Default stage ---
# A stage is a deployment slot, like "live". The name "$default"
# means requests go to the root URL with no path prefix.
# auto_deploy = true means every Terraform apply is immediately live.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}


# --- Integration ---
# Connects the API to Lambda. AWS_PROXY means API Gateway passes
# the full HTTP request to Lambda as-is and returns Lambda's
# response directly. No transformation happens in the middle.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.url_shortener.invoke_arn
  payload_format_version = "2.0"
}


# --- POST /shorten route ---
# Matches POST requests to the /shorten path.
# Sends matching requests to the Lambda integration above.
resource "aws_apigatewayv2_route" "post_shorten" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}


# --- GET /{id} route ---
# Matches GET requests to any path like /OddhuL.
# The {id} is a path parameter that handler.py reads.
resource "aws_apigatewayv2_route" "get_redirect" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}


# --- Lambda permission ---
# Explicitly grants API Gateway the right to invoke this Lambda.
# Without this, the API would exist but every request would get
# a 403 Internal Server Error from Lambda refusing to execute.
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
