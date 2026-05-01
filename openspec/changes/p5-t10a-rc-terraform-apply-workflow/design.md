# Design: RC Terraform Apply Workflow

## Context

`platform-infra` currently validates Terraform changes in CI, but operators do
not have a dedicated GitHub Actions path to apply the `rc` environment from the
repository. The change spans `platform-infra` and `org-dot-github`, touches CI
identity and deployment safety, and must preserve the current separation
between `rc` and `prod`.

The workflow also needs to support the follow-up clean-state RC validation task.
That means operators need a predictable path that shows the plan, applies only
the RC root, and leaves an auditable trail of what ran and why.

## Goals / Non-Goals

**Goals:**

- Provide one dedicated CI workflow that applies only `environments/rc`
- Use GitHub OIDC and GCP workload identity instead of static credentials
- Show operators the Terraform plan before the apply step runs
- Preserve Terraform locking and add GitHub-side concurrency protection
- Document who can trigger the workflow, what branch/ref it can use, and how to
  recover from a bad rollout

**Non-Goals:**

- Adding a prod apply workflow
- Implementing prod create/destroy/recover lifecycle controls
- Changing the committed RC deployment preset or enabling deployment by default
- Replacing existing PR validation workflows

## Decisions

### 1. Use a dedicated RC wrapper workflow with a reusable shared implementation

`platform-infra` should own a repo-local workflow whose responsibility is to
target `environments/rc` only. Shared apply mechanics should live in
`org-dot-github` so later infra repositories can reuse the same reviewed apply
pattern without copying YAML.

Alternative considered:

- Put the entire workflow only in `platform-infra`
  Rejected because the task explicitly affects `org-dot-github`, and shared
  apply behavior should stay centrally governed.

### 2. Use approved `workflow_dispatch` from the protected branch as the apply trigger

The apply workflow should run from a reviewed revision on the approved branch,
with human approval before the apply job proceeds. This keeps RC deploys
intentional while still satisfying the requirement for CI-managed apply.

Alternative considered:

- Auto-apply on every merge to `main`
  Rejected because it increases blast radius while the RC environment is still
  being brought online and validated.

### 3. Make plan output a first-class artifact of the workflow

The workflow should run `terraform plan` for `environments/rc`, capture a
machine-usable plan file for the approved apply step, and publish a readable
plan summary/log artifact for operators. The apply job should use the reviewed
plan from the same workflow run rather than re-planning implicitly.

Alternative considered:

- Run `terraform apply` directly without preserving the plan
  Rejected because it weakens reviewability and makes incident analysis harder.

### 4. Hard-code RC targeting and reject environment switching inputs

The workflow should not accept a free-form environment or root-path input.
`environments/rc` must be wired directly in the repo-local wrapper and validated
again in the shared workflow to prevent the RC path from being reused for prod.

Alternative considered:

- One generic apply workflow with an `env` input
  Rejected because the task explicitly requires protections against accidental
  prod execution from the RC path.

### 5. Use layered safety: Terraform lock timeout plus GitHub concurrency plus environment approval

Terraform already uses `-lock-timeout=5m` in repo entrypoints. The workflow
should preserve that setting and add GitHub Actions concurrency so only one RC
apply runs at a time. GitHub environment protection should gate the final apply
step behind the designated RC approvers.

Alternative considered:

- Rely on Terraform state locking alone
  Rejected because state locking prevents simultaneous state mutation but does
  not stop multiple CI runs from competing operationally or confusing operators.

### 6. Document rollback as forward-fix or re-apply from a known-good revision

The operator contract should avoid an automatic destroy/rollback path. The safe
recovery path is to inspect the visible plan/apply logs, revert or fix the
change, and re-run the RC workflow from a known-good revision.

Alternative considered:

- Automatic rollback on apply failure
  Rejected because Terraform changes can be partially applied and cannot be
  safely undone generically without environment-specific review.

## Risks / Trade-offs

- [Manual dispatch adds an extra human step] -> Mitigate with clear operator
  docs and GitHub environment approvals that keep the extra step intentional.
- [Shared reusable workflow changes can affect multiple repos] -> Mitigate by
  keeping the repo-local RC wrapper explicit and validating the shared workflow
  contract in `platform-infra`.
- [OIDC and workload identity setup can fail due to org or GCP policy drift] ->
  Mitigate by documenting required principals, roles, and repository bindings in
  the operator contract.
- [Saved plan files can become stale if the branch moves] -> Mitigate by
  binding the plan/apply sequence to one workflow run on one resolved commit.

## Migration Plan

1. Add or extend the reusable Terraform apply workflow in `org-dot-github`.
2. Add the RC-specific wrapper workflow in `platform-infra` with hard-coded
   `environments/rc` targeting.
3. Configure GitHub environment approval and required OIDC inputs for the RC
   apply path.
4. Dry-run the workflow against a non-destructive RC plan to confirm auth,
   state access, plan visibility, and concurrency behavior.
5. Document the trigger rules, approver expectations, and rollback path in the
   repo docs.
6. Use the workflow as the deployment path for the follow-up RC clean-state
   validation task.

Rollback strategy:

- Disable or revert the workflow change if the CI path itself is incorrect.
- For infrastructure drift introduced by a bad RC apply, revert or fix the
  Terraform change and re-run the workflow from a reviewed revision.

## Open Questions

- Which GitHub environment name and approver group should own RC apply approval?
- Does `org-dot-github` already expose a reusable Terraform apply workflow that
  can be extended, or do we need to introduce a new one?
