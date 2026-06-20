# Contributing

Thank you for taking the time to look at this project. Contributions of any size are welcome, whether that is a typo fix, a documentation improvement, or a suggestion on the infrastructure design.

---

## Reporting an issue

If something does not work as described, open a GitHub issue and include:

- The phase or file where the problem occurs
- The exact command or step that failed
- The error message or unexpected output
- The operating system and tool versions (`aws --version`, `terraform -version`, etc.)

Clear issue reports get faster responses.

---

## Submitting a pull request

1. Fork the repository and create a branch from `main`.
2. Make the change. Keep each pull request focused on one thing.
3. Test the change before opening the PR. If it touches Terraform, run
   `terraform plan` and include the output in the PR description.
4. Open the pull request against `main` with a short description of what
   changed and why.

---

## What is in scope

- Bug fixes in the Terraform, GitHub Actions workflows, or Lambda handler
- Improvements to the runbook or documentation
- Corrections to cost estimates or measured metrics
- Suggestions on IAM scoping or security approach

## What is out of scope

- Adding new tools or services that are not already part of the architecture.
  The tool choices are deliberate and documented in the README.
- Stretch tracks (EKS, CodePipeline, Go CLI) are planned and will be added
  in order. Please do not open PRs for those until the relevant phase starts.

---

## Code style

- Python: follow PEP 8. Add a comment where the reasoning is not obvious.
- Terraform: one resource per file, named clearly. No hardcoded values,
  use variables.
- Documentation: no contractions, no em dashes, plain and direct language.

---

## Questions

If something in the architecture or approach is unclear, open a discussion
or an issue. Questions are welcome.
