# Module Cost Presets

`platform-infra` keeps runtime topology selection in `deployment_preset`, and
now lets operators tune cost posture independently per module.

An optional `global_preset` can now set all of those defaults in one place.
Lower-level settings still work as overrides, so you can start from a bundle
and tweak only one module when needed.

Naming convention:

- variable: `<thing>_preset`
- local catalog: `<thing>_preset_catalog`

Examples:

- `deployment_preset` -> `deployment_preset_catalog`
- `vps_preset` -> `vps_preset_catalog`
- `cloudrun_preset` -> `cloudrun_preset_catalog`
- `artifact_registry_preset` -> `artifact_registry_preset_catalog`
- `secret_manager_preset` -> `secret_manager_preset_catalog`
- `global_preset` -> `global_preset_catalog`

## Global Presets

- `single-vps`
- `cheap-single-vps`
- `cloudrun-cloudsql`
- `cheap-cloudrun-cloudsql`
- `cloudrun-cdn-cloudsql`
- `cheap-cloudrun-cdn-cloudsql`
- `gke-cloudsql`
- `cheap-gke-cloudsql`

Example:

```hcl
global_preset = "cheap-cloudrun-cloudsql"
```

Example with one override:

```hcl
global_preset   = "cheap-cloudrun-cloudsql"
cloudrun_preset = "standard"
```

Use `inherit` for the module preset inputs when you want them to continue
following `global_preset`.

## Available Module Presets

- `vps_preset`
  - `standard`: keep the configured VM size, balanced disk, and static public IP
  - `cheap`: use a smaller VM, standard disk, smaller boot volume, and an
    ephemeral public IP
- `cloudrun_preset`
  - `standard`: keep the configured scaling and container limits
  - `cheap`: keep scale-to-zero, lower the max instance cap, reduce
    concurrency, and shrink the default memory reservation
- `artifact_registry_preset`
  - `standard`: keep the configured cleanup windows
  - `cheap`: prune untagged and SHA-tagged images more aggressively and retain
    fewer recent SHA images
- `secret_manager_preset`
  - `standard`: keep the configured telemetry profile and the Grafana ingest
    token secret contract
  - `cheap`: switch telemetry to `off`, which removes the Grafana runtime
    secret from the Cloud Run and GKE wiring and reduces Secret Manager
    footprint
- `cloudsql_profile`
  - existing profile selection remains the Cloud SQL sizing control
  - examples: `super_cheap`, `cheap_dev`, `rc`, `prod`

## Example Combinations

Cheap VPS, standard managed services:

```hcl
deployment_preset = "single-vps"
vps_preset        = "cheap"
```

Cheap Cloud Run and cheap registry retention, but keep Secret Manager
observability wiring:

```hcl
deployment_preset         = "cloudrun-cloudsql"
cloudrun_preset           = "cheap"
artifact_registry_preset  = "cheap"
secret_manager_preset     = "standard"
cloudsql_profile          = "cheap_dev"
```

Leanest managed baseline:

```hcl
deployment_preset         = "cloudrun-cloudsql"
cloudrun_preset           = "cheap"
artifact_registry_preset  = "cheap"
secret_manager_preset     = "cheap"
cloudsql_profile          = "super_cheap"
```

The equivalent single-setting version is:

```hcl
global_preset = "cheap-cloudrun-cloudsql"
```

## Notes

- `secret_manager_preset = "cheap"` affects runtime secret wiring by disabling
  the Grafana ingest token contract. It does not delete unrelated secrets.
- `artifact_registry_preset` is the closest equivalent here to "cheap Cloud
  Storage" because Artifact Registry storage is the container-image storage
  surface already managed in this repo.
- Region choice still matters for GCP free-tier eligibility. These module
  presets tune resource shapes and retention, not region policy.
