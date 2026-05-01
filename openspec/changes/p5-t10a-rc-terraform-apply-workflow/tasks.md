## 1. Shared Workflow Design

- [x] 1.1 Confirm the RC apply trigger model, approval gate, and branch/ref
  restrictions
- [x] 1.2 Add or extend the reusable Terraform apply workflow in
  `org-dot-github` for OIDC auth, plan visibility, artifact preservation, and
  concurrency controls

## 2. Repository Wiring

- [x] 2.1 Add the RC-specific workflow in `platform-infra` that hard-codes
  `environments/rc`
- [x] 2.2 Ensure the workflow preserves the `-lock-timeout=5m` convention and
  rejects non-RC targeting
- [x] 2.3 Verify required GitHub environment, workload identity, and remote
  state inputs are documented and wired

## 3. Documentation And Validation

- [x] 3.1 Document the RC operator contract, including who can trigger the
  workflow, approval rules, rollback expectations, and follow-up validation use
- [ ] 3.2 Validate the workflow path with repo checks and a non-destructive RC
  plan/apply dry run where credentials are available
