# Deployment Presets

`platform-infra` now keeps `rc` and `prod` as the only Terraform roots and
adds a second dimension called `deployment_preset`.

## Operator Model

Each environment root selects:

- `deployment_preset`
- `deployment_enabled`

`deployment_preset` chooses the topology.
`deployment_enabled` decides whether Terraform should actually create the
resources for that topology.

This replaces the old per-module activation toggles with one explicit preset.

## Preset Catalog

- `single-vps`
  - frontend: single VM
  - backend: single VM
  - database: single VM
- `cloudrun-cloudsql`
  - frontend: external/manual
  - backend: Cloud Run
  - database: Cloud SQL
- `cloudrun-cdn-cloudsql`
  - frontend: CDN/static hosting contract
  - backend: Cloud Run
  - database: Cloud SQL
- `gke-cloudsql`
  - frontend: CDN/static hosting contract
  - backend: GKE
  - database: Cloud SQL

## Current Defaults

- `environments/rc/terraform.tfvars`: `deployment_preset = "single-vps"`
- `environments/prod/terraform.tfvars`: `deployment_preset = "cloudrun-cloudsql"`

Both roots still default `deployment_enabled = false` to preserve the repo's
safe baseline while making the intended topology explicit.

## Output Contract

Each root now exports `deployment_contract` with:

- `active_preset`
- `frontend_contract`
- `backend_contract`
- `database_contract`
- `operational_contract`

`service_contracts` also includes these normalized preset-aware fields so
existing consumers can transition gradually.

## Runbook

For the operator workflow to switch an environment from one preset to another,
see [docs/runbooks/change-environment-preset.md](/C:/Users/Miquel/dev/platform-infra/docs/runbooks/change-environment-preset.md).
