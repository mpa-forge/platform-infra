# Deployment Presets

`platform-infra` now keeps `rc` and `prod` as the only Terraform roots and
adds a second dimension called `deployment_preset`.

## Operator Model

Each environment root selects:

- `global_preset` (optional)
- `deployment_preset`
- `deployment_enabled`

`deployment_preset` chooses the topology.
`deployment_enabled` decides whether Terraform should actually create the
resources for that topology.
When `global_preset` is set, it supplies a bundled topology plus module-level
cost defaults. Explicit lower-level settings still override that bundle.

Resolution order:

1. explicit lower-level value, if it is not `inherit`
2. `global_preset` default, if set
3. built-in fallback

This replaces the old per-module activation toggles with one explicit preset.
Cost tuning is now a second, independent layer applied through per-module
presets such as `vps_preset`, `cloudrun_preset`, `artifact_registry_preset`,
`secret_manager_preset`, and the existing `cloudsql_profile`.

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

- `environments/rc/terraform.tfvars`: `global_preset = "cheap-single-vps"`
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

## Cost Tuning

Deployment presets choose topology. They do not force one global cost posture.
Operators can mix module presets per environment, for example:

- `deployment_preset = "single-vps"` with `vps_preset = "cheap"`
- `deployment_preset = "cloudrun-cloudsql"` with:
  - `cloudrun_preset = "cheap"`
  - `artifact_registry_preset = "cheap"`
  - `secret_manager_preset = "cheap"`
  - `cloudsql_profile = "super_cheap"`

Or use a bundled shortcut and override only what you need:

- `global_preset = "cheap-single-vps"`
- `global_preset = "cheap-cloudrun-cloudsql"`
- `global_preset = "cheap-cloudrun-cloudsql"` plus `cloudrun_preset = "standard"`

See [docs/module-cost-presets.md](/C:/Users/Miquel/dev/platform-infra/docs/module-cost-presets.md)
for the module-level preset catalog.

## Runbook

For the operator workflow to switch an environment from one preset to another,
see [docs/runbooks/change-environment-preset.md](/C:/Users/Miquel/dev/platform-infra/docs/runbooks/change-environment-preset.md).
