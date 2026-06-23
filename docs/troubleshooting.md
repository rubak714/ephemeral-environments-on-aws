# Troubleshooting Log

Real errors hit during this project, with causes and fixes.

---

## Phase 3

### `lambda:TagResource` AccessDeniedException in GitHub Actions

**Error:**
```
Error: creating Lambda Function (url-shortener-pr-6): AccessDeniedException:
User is not authorized to perform: lambda:TagResource
```

**Cause:** The `github-actions-deployer` IAM policy in `infra/bootstrap/oidc.tf` was missing three Lambda permissions that Terraform calls when applying tags to a Lambda function.

**Fix:** Added `lambda:TagResource`, `lambda:ListTags`, and `lambda:GetFunctionCodeSigningConfig` to the Lambda statement in the policy, then ran `terraform -chdir=infra/bootstrap apply` to update the role.

---

### `Input required and not supplied: aws-region`

**Error:**
```
Error: Input required and not supplied: aws-region
```

**Cause:** The workflows used `${{ vars.AWS_REGION }}` which reads from the GitHub Variables tab. The value was added to the Secrets tab instead. GitHub treats these as two separate stores.

**Fix:** Changed `vars.AWS_REGION` to hardcode `eu-central-1` directly in the workflow (the region is not sensitive). Changed `vars.AWS_ROLE_ARN` to `secrets.AWS_ROLE_ARN` to match where the value was stored.

---

### Double slash `//shorten` in PR comment URL

**Error:** PR comment showed `https://abc.execute-api.eu-central-1.amazonaws.com//shorten` causing bad request.

**Cause:** The `aws_apigatewayv2_stage` resource outputs a URL with a trailing slash. The comment template appended `/shorten`, producing a double slash.

**Fix:** Added `| sed 's|/$||'` when reading the Terraform output to strip the trailing slash before saving to `$GITHUB_ENV`.

---

### `prevent_destroy` blocks bootstrap teardown

**Error:**
```
Error: Instance cannot be destroyed
Resource aws_s3_bucket.tfstate has lifecycle.prevent_destroy set
```

**Cause:** Running `terraform destroy` inside `infra/bootstrap/` targets the S3 state bucket, which has `lifecycle { prevent_destroy = true }` set intentionally.

**Why this is correct:** The S3 bucket holds Terraform state for every PR environment. Deleting it makes it impossible to track or destroy existing resources. The protection should never be removed while the project is active.

**Fix:** Do not destroy the bootstrap. To clean up a PR environment, run:
```bash
terraform -chdir=infra destroy -var="env_name=pr-6" -auto-approve
```
