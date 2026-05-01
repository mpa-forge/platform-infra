# RC Terraform Apply Workflow

This runbook defines the operator contract for the GitHub Actions workflow that
applies Terraform for the `rc` environment from `platform-infra`.

## Purpose

Use this workflow when you want the reviewed `main` branch state of
`platform-infra` to run `terraform apply` against `environments/rc` through
GitHub Actions.

This is the approved CI-managed RC deployment path for the Phase 5 `P5-T10A`
baseline. It is also the expected apply path for the follow-up `P5-T11`
clean-state RC validation task.

## Trigger Model

- workflow: `terraform-apply-rc`
- trigger: manual `workflow_dispatch`
- allowed ref: `main` only
- target root: `environments/rc` only

The workflow is intentionally hard-coded to the RC root and fails if the shared
workflow receives any other target path.

## Who Can Trigger It

- a repository maintainer with permission to run GitHub Actions workflows in
  `platform-infra`
- an approver allowed to pass the GitHub Environment gate for `rc-apply`

Current baseline ownership follows the shared access model:

- repo maintainer: `MiquelPiza`
- org admin / current RC approver baseline: `MiquelPiza`

If more maintainers are added later, keep this workflow gated behind the same
least-privilege review model.

## Required GitHub Configuration

Configure these repository variables in `platform-infra`:

- `RC_GCP_WORKLOAD_IDENTITY_PROVIDER`
  Example: full Workload Identity Provider resource for the RC deploy path
- `RC_GCP_CI_SERVICE_ACCOUNT`
  Example: RC-scoped CI deploy service account email

Configure this GitHub Environment in `platform-infra`:

- `rc-apply`

Recommended environment settings:

- required reviewers enabled
- reviewers limited to the RC deployment approvers
- optional environment-scoped variables or secrets only if later needed

## Required GCP Configuration

The GitHub OIDC principal must be allowed to impersonate the RC CI deploy
service account through Workload Identity Federation.

The RC CI deploy service account should have only the permissions needed to:

- read and write the RC Terraform state bucket
- manage resources in the `mpa-forge-bp-rc` project that the RC root owns
- read any supporting APIs required by Terraform providers during plan/apply

Do not use static service account keys for this workflow.

## What The Workflow Does

1. validates that the workflow is running from `refs/heads/main`
2. validates that the requested Terraform root is `environments/rc`
3. authenticates to GCP using GitHub OIDC and the configured RC service account
4. runs `terraform init` against the RC root with the shared remote backend
5. runs `terraform plan -lock-timeout=5m -out=terraform-rc.tfplan`
6. publishes a readable plan summary and uploads plan artifacts
7. waits for the `rc-apply` environment approval gate
8. downloads the reviewed plan artifact and runs
   `terraform apply -lock-timeout=5m terraform-rc.tfplan`
9. uploads apply logs as workflow artifacts

## Plan Visibility And Evidence

Each run publishes:

- a GitHub Actions step summary with a readable Terraform plan excerpt
- a `terraform-rc-plan` artifact containing:
  - `terraform-rc.tfplan`
  - `terraform-rc-plan.txt`
  - `terraform-rc-plan.log`
- a `terraform-rc-apply` artifact containing:
  - `terraform-rc-apply.log`
  - plan log copies used for incident review

Review the plan summary and artifact before approving the `rc-apply`
environment gate.

## Concurrency And Locking

- GitHub Actions concurrency allows only one RC apply workflow run at a time
- Terraform uses `-lock-timeout=5m` to match the repo convention and wait for
  the GCS state lock instead of failing immediately

If another RC apply is already in progress, wait for it to complete before
starting a new run.

## Rollback Expectations

This workflow does not perform automatic rollback.

If a run is incorrect or partially fails:

1. inspect the plan and apply artifacts
2. identify the bad Terraform change or missing prerequisite
3. revert or fix the code on a branch
4. merge the reviewed fix to `main`
5. re-run `terraform-apply-rc`

Treat RC recovery as a forward-fix or known-good re-apply flow, not as an
automatic destroy.

## Related Docs

- [README.md](/C:/Users/Miquel/dev/platform-infra/README.md)
- [docs/terraform-remote-state.md](/C:/Users/Miquel/dev/platform-infra/docs/terraform-remote-state.md)
- [docs/runbooks/change-environment-preset.md](/C:/Users/Miquel/dev/platform-infra/docs/runbooks/change-environment-preset.md)
