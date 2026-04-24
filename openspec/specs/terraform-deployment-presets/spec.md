# terraform-deployment-presets Specification

## Purpose
Define a preset-driven Terraform environment assembly model that keeps `rc` and
`prod` as the only top-level roots while allowing runtime topology to vary by
selected preset.

## Requirements
### Requirement: Environment roots select a deployment preset

The `rc` and `prod` Terraform roots SHALL select runtime topology through a
`deployment_preset` input rather than directly exposing per-module activation
flags.

#### Scenario: RC root uses the committed preset default

- **WHEN** the committed RC environment values are used
- **THEN** the RC root MUST default to the `single-vps` deployment preset.

#### Scenario: prod root uses the committed preset default

- **WHEN** the committed prod environment values are used
- **THEN** the prod root MUST default to the `cloudrun-cloudsql` deployment
  preset.

### Requirement: Preset selection is validated explicitly

Environment roots SHALL reject unsupported preset names at the root input
contract.

#### Scenario: Unsupported preset is provided

- **WHEN** an operator sets `deployment_preset` to an unknown value
- **THEN** Terraform validation MUST fail before module wiring is evaluated.

### Requirement: Shared stack module derives topology

A shared environment assembly module SHALL derive runtime topology and module
activation from the selected deployment preset.

#### Scenario: single-vps preset is selected

- **WHEN** `deployment_preset` is `single-vps`
- **THEN** the shared stack MUST derive a topology with frontend, backend, and
  database runtime kinds set to `vps`.

#### Scenario: cloudrun-cloudsql preset is selected

- **WHEN** `deployment_preset` is `cloudrun-cloudsql`
- **THEN** the shared stack MUST derive a topology with backend runtime kind
  `cloud_run` and database runtime kind `cloudsql`.

#### Scenario: gke-cloudsql preset is selected

- **WHEN** `deployment_preset` is `gke-cloudsql`
- **THEN** the shared stack MUST derive a topology with backend runtime kind
  `gke` and database runtime kind `cloudsql`.

### Requirement: Deployment enablement stays explicit

Preset selection SHALL be separate from whether the infrastructure is created.

#### Scenario: Deployment is disabled

- **WHEN** `deployment_enabled` is `false`
- **THEN** the selected preset MUST remain visible in root outputs and
  documentation while managed resources remain disabled.

### Requirement: Single VPS runtime path

The preset catalog SHALL support a low-cost single-VM runtime path for basic
projects and testing environments.

#### Scenario: Single VPS preset is enabled

- **WHEN** the selected preset is `single-vps` and deployment is enabled
- **THEN** Terraform MUST manage one VM, a public IP, ingress rules, and a
  runtime contract for colocated frontend, backend, and PostgreSQL workloads.

### Requirement: Stable preset-aware outputs

Environment roots SHALL export a normalized deployment contract regardless of
the active preset.

#### Scenario: Downstream consumers inspect deployment outputs

- **WHEN** tooling or documentation reads root outputs
- **THEN** it MUST be able to consume `active_preset`, `frontend_contract`,
  `backend_contract`, `database_contract`, and `operational_contract` without
  referencing preset-specific internals.

### Requirement: Existing runtime modules remain composable

The shared stack SHALL compose existing runtime and secret modules instead of
duplicating their infrastructure logic.

#### Scenario: Cloud Run runtime is selected

- **WHEN** the selected preset uses Cloud Run
- **THEN** the shared stack MUST obtain the backend runtime contract from the
  existing Cloud Run API module.

#### Scenario: GKE runtime is selected

- **WHEN** the selected preset uses GKE
- **THEN** the shared stack MUST obtain cluster and secret-sync metadata from
  the existing GKE and secrets modules.
