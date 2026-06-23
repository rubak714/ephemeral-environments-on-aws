# outputs.tf
# I print the live API URL after every apply so I can test immediately.
#
# In Phase 3, the GitHub Actions workflow reads this output automatically
# and posts it as a comment on the pull request.


output "api_url" {
  description = "Live Invoke URL for this environment. Paste into curl to test."
  value       = aws_apigatewayv2_stage.default.invoke_url
}
