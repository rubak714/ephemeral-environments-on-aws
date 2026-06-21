# ============================================================
# outputs.tf
# Values that Terraform prints after apply finishes.
#
# The api_url is the live Invoke URL for this environment.
# In Phase 2 this is used immediately to run curl tests.
# In Phase 3 the GitHub Actions workflow will read this output
# and post it as a PR comment automatically.
# ============================================================

output "api_url" {
  description = "The public Invoke URL for this environment. Use this with curl to test."
  value       = aws_apigatewayv2_stage.default.invoke_url
}
