# bootstrap/oidc.tf
# I set up the trust between GitHub Actions and AWS here.
#
# How OIDC works in plain English:
# When a GitHub Actions workflow runs, GitHub mints a short-lived
# signed token that says "I am workflow X in repo Y, running right now."
# AWS checks that token against this OIDC provider, confirms the
# signature is genuinely from GitHub, then hands back a temporary
# AWS session. No password is ever stored anywhere.
#
# Without OIDC the alternative is to store AWS_ACCESS_KEY_ID and
# AWS_SECRET_ACCESS_KEY as GitHub secrets. Those never expire and
# are a liability. OIDC tokens expire after 15 minutes.


# -----------------------------------------------------------------
# OIDC provider
# -----------------------------------------------------------------

# This tells AWS: "I trust tokens signed by GitHub's identity service."
# The thumbprint is GitHub's TLS certificate fingerprint.
# AWS uses it to verify the token signature is really from GitHub.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # "sts.amazonaws.com" is the AWS service that will receive these tokens.
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's current TLS thumbprint.
  # This value is stable and published in GitHub's documentation.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}


# -----------------------------------------------------------------
# Trust policy for the GitHub Actions role
# -----------------------------------------------------------------

# I write the trust policy as a data source so Terraform can
# validate the JSON before creating the role.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # This condition is the important security gate.
    # It means ONLY workflows from my specific repo can assume this role.
    # Any other GitHub repo that tries gets denied.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}


# -----------------------------------------------------------------
# IAM role that GitHub Actions will assume
# -----------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Project = "ephemeral-environments"
    Purpose = "github-actions-cicd"
  }
}


# -----------------------------------------------------------------
# Permission policy for the deployer role
# -----------------------------------------------------------------

# This role needs to run terraform apply and terraform destroy
# for every PR environment. That means it must be able to create
# and delete Lambda, DynamoDB, API Gateway, IAM roles, and
# CloudWatch log groups. I scope each permission as tightly as I can.
data "aws_iam_policy_document" "github_actions_permissions" {

  # S3: read and write state files in the tfstate bucket only.
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*",
    ]
  }

  # DynamoDB: acquire and release the state lock only.
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [aws_dynamodb_table.tfstate_lock.arn]
  }

  # Lambda: create, update, and delete PR environment functions.
  statement {
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy",
      "lambda:ListVersionsByFunction",
      "lambda:PublishVersion",
    ]
    resources = ["*"]
  }

  # DynamoDB: create and delete the url tables for each PR environment.
  # Note: this is separate from the lock table permissions above.
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
    ]
    resources = ["*"]
  }

  # API Gateway: create and delete the HTTP APIs for each PR environment.
  statement {
    effect = "Allow"
    actions = [
      "apigateway:POST",
      "apigateway:GET",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE",
      "apigateway:TagResource",
    ]
    resources = ["*"]
  }

  # IAM: create and delete the Lambda execution roles for each PR environment.
  # I restrict this to role names that start with "url-shortener-" so the
  # deployer cannot create arbitrary admin roles.
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
    ]
    resources = ["arn:aws:iam::*:role/url-shortener-*"]
  }

  # CloudWatch Logs: create and delete log groups for each Lambda function.
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsLogGroup",
      "logs:PutRetentionPolicy",
      "logs:TagLogGroup",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions-deployer-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
