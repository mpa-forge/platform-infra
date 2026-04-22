## Why

`P5-T04` needs to turn the Cloud Run API skeleton into the deployable baseline
runtime for both `rc` and `prod`. The current module shape is close, but it
does not yet fully specify the runtime contract around ingress, launch stage,
revision metadata, Cloud SQL socket wiring, IAM, and environment-root controls.

## What Changes

- Harden the Cloud Run API Terraform module around a complete baseline runtime
  contract.
- Add explicit module inputs for runtime path, startup env, container port,
  launch stage annotations, invocation policy, SQL socket mount, and optional
  unauthenticated ingress.
- Wire `rc` and `prod` roots to pass backend API startup requirements,
  observability env, Cloud SQL connection settings, and environment-specific
  scaling controls.
- Export Cloud Run service URI, service account, and service/runtime contract
  values for downstream routing and validation tasks.

## Capabilities

### New Capabilities

- `terraform-cloudrun-api-baseline`: Defines the Cloud Run API service,
  runtime service account, IAM, secret/env wiring, Cloud SQL attachment, and
  environment-root binding contract for the Phase 5 baseline API runtime.

### Modified Capabilities

- `terraform-network-baseline`: Clarifies that downstream runtime modules can
  consume network outputs without changing the established network resource
  contract.

## Impact

- Terraform module: `modules/cloudrun_api`.
- Environment roots: `environments/rc` and `environments/prod`.
- Operator documentation: Terraform file guide and Cloud Run runtime contract
  notes.
- Future tasks: `P5-T09`, `P5-T14`, `P5-T15`, and Phase 6 API deployment
  tasks consume the Cloud Run service outputs and runtime-path contract.
