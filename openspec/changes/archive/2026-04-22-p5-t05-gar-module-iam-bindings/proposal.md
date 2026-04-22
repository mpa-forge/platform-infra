## Why

`P5-T05` must make container image storage and pull/push authorization
reproducible before Cloud Run deployments and worker jobs can use immutable
images. The current GAR module can create repositories, but it does not yet
capture retention policy, image URI outputs, regional guardrails, or the
least-privilege CI/runtime IAM contract.

## What Changes

- Complete the GAR Terraform module for the minimal repository set required now:
  `apps`, `workers`, and `tools`.
- Keep Artifact Registry regional and aligned with the environment's Cloud Run
  region, defaulting to `us-east4`.
- Add cleanup policies that prune old untagged artifacts and old immutable
  `sha-` images while keeping recent images for rollback.
- Preserve immutable SHA tag expectations and expose repository/image URI
  prefixes for downstream CI and deployment tasks.
- Keep `rc` and `prod` repositories separate by project and root path while
  avoiding unnecessary cross-environment image duplication.
- Add least-privilege IAM bindings: CI principals can push, runtime principals
  can pull.

## Capabilities

### New Capabilities

- `terraform-gar-baseline`: Defines regional Artifact Registry repositories,
  repository cleanup policy, CI writer bindings, runtime reader bindings, and
  image URI contracts for the Phase 5 platform baseline.

### Modified Capabilities

- `terraform-cloudrun-api-baseline`: Clarifies that the Cloud Run API runtime
  consumes regional GAR image URI outputs and receives reader access through
  repository-scoped IAM.

## Impact

- Terraform module: `modules/gar`.
- Environment roots: `environments/rc` and `environments/prod`.
- Runtime identity integration: Cloud Run API service account pull access now
  feeds into the GAR repository contract.
- Future tasks: Phase 4 image publishing, Phase 6 Cloud Run deployments, and
  Phase 8 image retention/cost controls consume the GAR outputs and policy.
