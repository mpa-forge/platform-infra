## 1. Module Contract

- [x] 1.1 Extend `modules/cloudrun_api` variables for runtime path, port,
  startup probe, launch stage annotations, public invocation policy, Cloud SQL
  mount path, and env contract validation.
  Sub-agent: Local
  Ownership: `modules/cloudrun_api/**`
  Blocking: Yes - downstream root wiring depends on the module contract.
- [x] 1.2 Update `modules/cloudrun_api` resources and outputs to create the
  complete Cloud Run v2 service, runtime service account, IAM bindings, secret
  access, Cloud SQL attachment, invoker policy, and service/runtime outputs.
  Sub-agent: Local
  Ownership: `modules/cloudrun_api/**`
  Blocking: Yes.

## 2. Environment Bindings

- [x] 2.1 Wire `environments/rc` to pass backend startup env, auth inputs,
  database URL, scaling/concurrency/runtime controls, and Cloud SQL attachment
  values into the Cloud Run API module.
  Sub-agent: Local
  Ownership: `environments/rc/**`
  Blocking: Yes.
- [x] 2.2 Mirror the same Cloud Run API baseline contract in
  `environments/prod` with prod-specific defaults and isolation.
  Sub-agent: Local
  Ownership: `environments/prod/**`
  Blocking: Yes.

## 3. Documentation And Validation

- [x] 3.1 Update Terraform documentation so operators can understand the
  Cloud Run API runtime contract and the boundaries left to later tasks.
  Sub-agent: Local
  Ownership: `docs/**`, `README.md`
  Blocking: No.
- [x] 3.2 Run `make terraform-validate`, `make terraform-plan ENV=rc`, and
  `make terraform-plan ENV=prod`; capture any validation caveats.
  Sub-agent: Local
  Ownership: Validation only
  Blocking: Yes.
- [x] 3.3 Update this task list and validate the OpenSpec change.
  Sub-agent: Local
  Ownership: `openspec/changes/p5-t04-cloudrun-api-baseline-runtime/**`
  Blocking: Yes.
