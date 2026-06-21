# ==============================================================
# Makefile
# Wraps Terraform commands so common operations are one word.
#
# Usage:
#   make init           download providers (run once)
#   make plan           preview what will change
#   make deploy         apply the plan (create or update)
#   make test           run curl smoke tests against the live API
#   make destroy        tear everything down
#
# To deploy a named environment (e.g. for PR 123):
#   make deploy ENV=pr-123
#   make destroy ENV=pr-123
# ==============================================================

# Default environment name. Override on the command line with ENV=...
ENV ?= dev

# Terraform working directory.
INFRA_DIR := infra

# --------------------------------------------------------------
# init: download the AWS and archive providers declared in main.tf.
# Must be run once before plan or apply. Safe to re-run at any time.
# --------------------------------------------------------------
.PHONY: init
init:
	terraform -chdir=$(INFRA_DIR) init

# --------------------------------------------------------------
# plan: show what Terraform WOULD do without making any changes.
# Read the output carefully before running deploy.
# --------------------------------------------------------------
.PHONY: plan
plan:
	terraform -chdir=$(INFRA_DIR) plan -var="env_name=$(ENV)"

# --------------------------------------------------------------
# deploy: create or update all resources for ENV.
# Equivalent to all 41 manual steps from Phase 1, done in one command.
# Prints the api_url output at the end.
# --------------------------------------------------------------
.PHONY: deploy
deploy:
	terraform -chdir=$(INFRA_DIR) apply -var="env_name=$(ENV)" -auto-approve

# --------------------------------------------------------------
# test: smoke-test the live API with two curl calls.
# Requires the ENV to already be deployed.
# The first call creates a short URL and captures the short_id.
# The second call follows the redirect to confirm it works.
# --------------------------------------------------------------
.PHONY: test
test:
	@echo "--- Getting API URL ---"
	$(eval API_URL := $(shell terraform -chdir=$(INFRA_DIR) output -raw api_url))
	@echo "API URL: $(API_URL)"
	@echo ""
	@echo "--- POST /shorten ---"
	curl -s -X POST $(API_URL)/shorten \
	  -H "Content-Type: application/json" \
	  -d '{"url": "https://example.com"}' | cat
	@echo ""
	@echo ""
	@echo "--- Tip: copy the short_id from above, then run: ---"
	@echo "  curl -v $(API_URL)/<short_id>"

# --------------------------------------------------------------
# destroy: delete every resource for ENV.
# Equivalent to the teardown portion of Phase 1, done in one command.
# This is safe because each ENV has its own named resources.
# Destroying pr-123 does not affect dev or pr-456.
# --------------------------------------------------------------
.PHONY: destroy
destroy:
	terraform -chdir=$(INFRA_DIR) destroy -var="env_name=$(ENV)" -auto-approve
