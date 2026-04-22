# Cloud SQL PostgreSQL

`modules/cloudsql` owns the Phase 5 managed PostgreSQL baseline for the API.
The environment roots keep the module disabled by default until operators are
ready to seed secret payloads and run environment applies.

## Runtime Contract

Cloud runtime database configuration is split into non-secret connection values
and one password-only secret:

- `DB_HOST`: Cloud SQL Unix socket host path, for example
  `/cloudsql/<project>:<region>:<instance>`
- `DB_NAME`: API application database name
- `DB_USER`: API application database user
- `DB_PASSWORD`: Secret Manager-backed database password

Terraform must not commit a full database URL containing credentials. The
`backend-api` runtime and migration entrypoints build the PostgreSQL connection
string from these values for Cloud Run and future GKE deployments.

Local development may keep using `DATABASE_URL` through the backend repo-local
`.env` file because the local Compose database does not use Cloud SQL sockets.

## Secret Payload Setup

Terraform creates the Secret Manager placeholder named
`api-db-password-<env>` and grants the Cloud Run runtime service account access
through the Cloud Run module secret-env contract.

Before enabling Cloud Run against the managed database, an operator must add the
secret payload outside committed files:

```bash
printf '%s' '<strong-generated-password>' | gcloud secrets versions add api-db-password-rc --data-file=- --project mpa-forge-bp-rc
printf '%s' '<strong-generated-password>' | gcloud secrets versions add api-db-password-prod --data-file=- --project mpa-forge-bp-prod
```

Use environment-specific passwords. Do not reuse the RC password in prod.

## Connectivity

The Cloud SQL instance uses private IP only and depends on the network module's
private service access connection. The Cloud Run API module mounts the Cloud
SQL Unix socket volume at `/cloudsql` and grants the runtime service account
`roles/cloudsql.client` when a Cloud SQL connection name is configured.

The optional GKE path should consume the same connection contract later, with
`DB_PASSWORD` delivered through the P5-T07 GSM and ESO path.

## Cost Profiles

Each environment root exposes `cloudsql_profile` so operators can switch the
database cost and durability posture without editing module internals.

Available profiles:

- `super_cheap`: `ENTERPRISE`, `db-f1-micro`, zonal, HDD, 10 GB, backups off,
  PITR off. Lowest Cloud SQL floor; useful only for disposable environments.
- `cheap_dev`: `ENTERPRISE`, `db-g1-small`, zonal, HDD, 10 GB, backups on,
  PITR off. Comfortable low-cost development or RC smoke testing.
- `rc`: `ENTERPRISE`, `db-custom-1-3840`, zonal, SSD, 20 GB, backups and PITR
  on. Default RC integration profile.
- `prod`: `ENTERPRISE`, `db-custom-2-7680`, regional HA, SSD, 50 GB, backups
  and PITR on. Safer production profile with a higher fixed cost.

Example override:

```bash
terraform -chdir=environments/rc plan -var='cloudsql_profile=cheap_dev'
```

Cloud SQL does not scale to zero. To avoid the fixed CPU and memory cost, keep
`module_activation.cloudsql = false` or use a suspend/resume flow that deletes
or recreates the instance while preserving the required data externally.

## Outputs

Environment roots export `service_contracts.api_database_contract` with:

- instance name
- instance connection name
- profile, edition, and tier
- database name
- database user
- runtime host/socket path
- password secret name

Downstream tasks and runbooks should consume this output instead of referencing
module-internal resources.
