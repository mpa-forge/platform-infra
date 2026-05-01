## Why

`platform-infra` can validate Terraform changes in CI today, but it does not
yet provide a controlled path to apply the `rc` environment from GitHub
Actions. We need an auditable `rc` deployment workflow before running the
clean-state environment bring-up task, while keeping `prod` isolated behind
stricter lifecycle controls.

## What Changes

- Add a dedicated CI workflow path that applies only `environments/rc` from
  `platform-infra`.
- Use workload identity / OIDC authentication and shared remote state access
  instead of long-lived static credentials.
- Surface Terraform plan details before apply, preserve plan/apply logs, and
  keep the existing `-lock-timeout=5m` convention.
- Add concurrency and environment guards so the RC workflow cannot target
  `prod` accidentally.
- Document the operator contract for triggers, branch gates, approvals,
  rollback expectations, and how this workflow feeds the later RC validation
  runbook.

## Capabilities

### New Capabilities
- `terraform-rc-apply-workflow`: CI-managed Terraform plan/apply workflow for
  the `rc` environment with explicit root targeting, OIDC authentication, plan
  visibility, and protections against prod execution.

### Modified Capabilities

## Impact

- Affected repos: `platform-infra`, `org-dot-github`
- Affected systems: GitHub Actions, GCP workload identity, Terraform remote
  state access, RC deployment operations
- Expected artifacts: workflow definitions, reusable workflow wiring or shared
  action inputs, and operator-facing documentation for RC apply behavior
