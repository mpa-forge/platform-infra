## 1. GAR Module Contract

- [x] 1.1 Add cleanup policy inputs and repository validation to
  `modules/gar`.
  Sub-agent: Local
  Ownership: `modules/gar/**`
  Blocking: Yes.
- [x] 1.2 Implement Artifact Registry cleanup policies and expand module
  outputs for repository/image URI contracts.
  Sub-agent: Local
  Ownership: `modules/gar/**`
  Blocking: Yes.

## 2. Environment Bindings

- [x] 2.1 Wire `environments/rc` with regional `apps`, `workers`, and `tools`
  repositories, cleanup defaults, CI writer member variables, and API runtime
  reader access on `apps`.
  Sub-agent: Local
  Ownership: `environments/rc/**`
  Blocking: Yes.
- [x] 2.2 Mirror the GAR baseline in `environments/prod` while preserving
  separate project boundaries and no implicit image duplication from `rc`.
  Sub-agent: Local
  Ownership: `environments/prod/**`
  Blocking: Yes.

## 3. Documentation And Validation

- [x] 3.1 Document GAR repository purpose, immutable SHA tag contract,
  cleanup policy, and IAM split.
  Sub-agent: Local
  Ownership: `docs/**`, `README.md`
  Blocking: No.
- [x] 3.2 Run Terraform formatting, validation, default plans, GAR-enabled
  plans for `rc` and `prod`, and OpenSpec validation.
  Sub-agent: Local
  Ownership: Validation only
  Blocking: Yes.
- [x] 3.3 Mark tasks complete after validation evidence is collected.
  Sub-agent: Local
  Ownership: `openspec/changes/p5-t05-gar-module-iam-bindings/**`
  Blocking: Yes.
