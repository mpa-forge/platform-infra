## Why

P5-T06 needs to turn the current placeholder Cloud SQL skeleton into a deployable PostgreSQL baseline that can be consumed by the Cloud Run API path without committing database credentials into Terraform values. This is needed now because the Cloud Run baseline already attaches to Cloud SQL, but the database user, password-secret contract, and backend startup shape still rely on a placeholder full `DATABASE_URL`.

## What Changes

- Complete the Terraform Cloud SQL PostgreSQL module with instance, backup, maintenance, private networking, application database, application user, and IAM/auth baseline outputs.
- Define the API database credential contract as non-secret connection inputs plus a Secret Manager-backed password, never a committed full connection string with embedded credentials.
- Update environment roots so Cloud Run receives `DB_HOST` or Cloud SQL socket path, `DB_NAME`, `DB_USER`, and secret-backed `DB_PASSWORD` instead of a plaintext placeholder `DATABASE_URL`.
- Update `backend-api` during implementation so runtime configuration and migration entrypoints can build the Postgres connection string from the split database env contract while preserving local `DATABASE_URL` compatibility where useful.
- Keep `rc` and `prod` database resources separated by project, root path, names, IAM, secrets, and deletion-protection defaults.

## Capabilities

### New Capabilities

- `terraform-cloudsql-postgres`: Managed PostgreSQL instance, database, user, private networking, backup, maintenance, auth, and credential-output contract for the API.

### Modified Capabilities

- `terraform-cloudrun-api-baseline`: Replace the placeholder full API database URL runtime injection with split DB env values plus a secret-backed `DB_PASSWORD`.

## Impact

- Affected repos: `platform-infra`, `backend-api`.
- Affected Terraform: `modules/cloudsql/**`, `modules/secrets/**`, `modules/cloudrun_api/**` if needed, `environments/rc/**`, `environments/prod/**`, and root outputs/docs.
- Affected backend API code/docs: startup config parsing, migration entrypoint env handling, `.env.example`, runtime docs, and tests.
- Affected systems: Cloud SQL private IP, Secret Manager password delivery, Cloud Run Cloud SQL attachment, optional future GKE database contract.
