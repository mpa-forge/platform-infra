# Cloud Run API Runtime

This document describes the Phase 5 Cloud Run API baseline owned by
`modules/cloudrun_api` and wired from `environments/rc` and
`environments/prod`.

## Runtime Contract

Cloud Run is the first API runtime path. Each environment root selects it
explicitly with `API_RUNTIME_PATH=cloud_run` and keeps the optional GKE path
disabled unless a later reviewed change enables it.

The Cloud Run service receives the backend API startup contract:

- `APP_ENV`
- `LOG_LEVEL`
- `HTTP_PORT`
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `AUTH_ISSUER_URL`
- `AUTH_AUDIENCE`
- `API_RUNTIME_PATH`
- `OTEL_MODE`
- `OBS_TELEMETRY_PROFILE`
- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `GRAFANA_CLOUD_INSTANCE_ID`
- `DB_PASSWORD`
- `GRAFANA_OTLP_INGEST_TOKEN` when telemetry is enabled

`DB_PASSWORD` is always injected from Secret Manager. The Grafana ingest token
is injected only when telemetry is enabled by the selected secret-manager
preset.
The module grants the runtime service account
`roles/secretmanager.secretAccessor` only for secret env vars listed in
`runtime_secret_access_env_names`. This keeps IAM grants explicit and
least-privilege even if additional secret env vars are added later.

The module also exports `runtime_secret_access_contract` so environment outputs
can verify which secret env vars and Secret Manager IDs are actually bound to
runtime IAM.

## Cloud SQL Contract

When the environment root enables Cloud SQL and passes an instance connection
name, the module:

- attaches the Cloud SQL instance to the Cloud Run revision template
- mounts the Unix socket volume at `/cloudsql`
- grants the runtime service account `roles/cloudsql.client`

`P5-T06` still owns database users, password material, and final live database
connectivity validation. The canonical cloud database contract is now split
into plain `DB_HOST`, `DB_NAME`, and `DB_USER` values plus Secret
Manager-backed `DB_PASSWORD`; Terraform must not commit a full database URL
containing credentials.

## Ingress And Invocation

The default ingress is internal/load-balancer only:

```hcl
ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
```

Public unauthenticated invocation is disabled by default. The module grants
`roles/run.invoker` to `allUsers` only when an environment root explicitly sets
`api_allow_unauthenticated = true`.

The later `/api/*` routing task owns load-balancer, certificate, and URL map
wiring in front of this service.

## Validation

Use repo-local Terraform entrypoints:

```bash
make terraform-validate
make terraform-plan ENV=rc
make terraform-plan ENV=prod
```

Default `terraform.tfvars` files keep resource creation disabled until image
publishing, secret payloads, Cloud SQL users, and CI apply controls are ready.
