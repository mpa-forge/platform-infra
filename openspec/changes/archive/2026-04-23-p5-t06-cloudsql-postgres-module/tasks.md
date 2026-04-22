## 1. Terraform Cloud SQL Baseline

- [x] 1.1 Complete `modules/cloudsql` inputs, resources, validation, and outputs for PostgreSQL instance, private IP, backups, PITR, maintenance, database, application user, deletion protection, and labels.
  Sub-agent: `openspec_implementer`
  Ownership: `platform-infra/modules/cloudsql/**`
  Expected output: Focused Terraform module changes and changed-file list.
  Blocking: No - environment root and docs work can proceed after module interface is clear.
- [x] 1.2 Add or adjust Secret Manager module support needed for the API database password placeholder/accessor contract without committing secret payloads.
  Sub-agent: `openspec_implementer`
  Ownership: `platform-infra/modules/secrets/**`
  Expected output: Secret contract support and changed-file list.
  Blocking: Partial - Cloud Run wiring depends on the final secret output shape.
- [x] 1.3 Wire `environments/rc` and `environments/prod` to pass Cloud SQL inputs, password secret references, Cloud Run split DB env vars, IAM accessors, and stable root outputs.
  Sub-agent: `openspec_implementer`
  Ownership: `platform-infra/environments/rc/**`, `platform-infra/environments/prod/**`
  Expected output: Environment-root wiring and changed-file list.
  Blocking: Partial - depends on module interfaces from 1.1 and 1.2.

## 2. Backend API Runtime Contract

- [x] 2.1 Update `backend-api` config loading so cloud/runtime startup can compose the Postgres DSN from `DB_HOST` or Cloud SQL socket path, `DB_NAME`, `DB_USER`, and `DB_PASSWORD`, while preserving local `DATABASE_URL` compatibility where appropriate.
  Sub-agent: `openspec_refactorer`
  Ownership: `backend-api/internal/config/**`, `backend-api/cmd/api/**`
  Expected output: Runtime config changes, tests, and changed-file list.
  Blocking: No - Terraform docs can proceed in parallel.
- [x] 2.2 Update `backend-api` migration entrypoint and docs so migration commands can use the same split DB contract or local `DATABASE_URL`.
  Sub-agent: `openspec_refactorer`
  Ownership: `backend-api/cmd/migrate/**`, `backend-api/README.md`, `backend-api/docs/**`, `backend-api/.env.example`
  Expected output: Migration env support, docs, tests where needed, and changed-file list.
  Blocking: No - can run after 2.1 or alongside if ownership stays clear.

## 3. Documentation and Contracts

- [x] 3.1 Update `platform-infra` docs to describe the Cloud SQL module, password-only Secret Manager contract, operator secret setup expectations, and Cloud Run/GKE database connection shape.
- [x] 3.2 Update root/module output documentation so later P5-T07, P5-T09, P5-T11, P5-T14, and P5-T16 work can consume the database contract without inspecting module internals.

## 4. Validation

- [x] 4.1 Run Terraform formatting and validation for `platform-infra`.
- [x] 4.2 Run default-disabled `make terraform-plan ENV=rc` and `make terraform-plan ENV=prod`.
- [x] 4.3 Run Cloud SQL/secrets/Cloud Run enabled plans for `rc` and `prod`, capturing that database resources and password-only secret delivery are planned.
- [x] 4.4 Run `backend-api` formatting and tests covering config loading and migration env handling.
- [x] 4.5 Run `openspec validate --specs --strict` in `platform-infra`.
