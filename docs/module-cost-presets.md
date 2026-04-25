# Module Cost Presets

`platform-infra` keeps runtime topology selection in `deployment_preset`, and
now lets operators tune cost posture independently per module.

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

## Notes

- `secret_manager_preset = "cheap"` affects runtime secret wiring by disabling
  the Grafana ingest token contract. It does not delete unrelated secrets.
- `artifact_registry_preset` is the closest equivalent here to "cheap Cloud
  Storage" because Artifact Registry storage is the container-image storage
  surface already managed in this repo.
- Region choice still matters for GCP free-tier eligibility. These module
  presets tune resource shapes and retention, not region policy.
