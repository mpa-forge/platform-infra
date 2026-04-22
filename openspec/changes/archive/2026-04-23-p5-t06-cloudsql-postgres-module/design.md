## Context

`platform-infra` already has disabled-by-default environment roots, a network module with private service access, a Cloud Run API module with Cloud SQL attachment support, a Secret Manager placeholder module, and a skeletal `modules/cloudsql`. The current environment roots compose `DATABASE_URL` with `change-me`, which violates the P5-T06/P5-T07 password-only secret direction and would make the backend runtime depend on a committed full connection string.

The implementation must update `backend-api` as part of the same change. The OpenSpec contract lives here because P5-T06 is owned by `platform-infra`, but the runtime must actually understand the split database variables for the infrastructure contract to be usable.

## Goals / Non-Goals

**Goals:**

- Create a deployable Cloud SQL PostgreSQL module for `rc` and `prod`.
- Use private IP networking through the network module private service access contract.
- Configure backups, point-in-time recovery, maintenance window, deletion protection, database flags where needed, and environment-specific labels.
- Create the application database and application user from Terraform-managed inputs.
- Source only the API database password from Secret Manager at runtime.
- Export stable module/root outputs for Cloud Run, optional GKE, operations, and later suspend/resume work.
- Update `backend-api` to support split DB connection variables for runtime and migration commands.

**Non-Goals:**

- Running `terraform apply` against live environments.
- Creating final production secret payload values in repo files.
- Introducing full GKE database deployment manifests or ESO synchronization; P5-T07 owns the broader GSM/ESO integration.
- Changing the environment model, region standard, or Cloud Run baseline runtime path.

## Decisions

1. Use split DB env variables as the canonical cloud runtime contract.

   Cloud Run will receive non-secret `DB_HOST`, `DB_NAME`, and `DB_USER` values plus secret-backed `DB_PASSWORD`. The backend will compose the Postgres DSN at startup. This avoids storing a full credential-bearing `DATABASE_URL` in Terraform values and matches the P5-T06/P5-T07 direction. The local developer path can keep accepting `DATABASE_URL` for compatibility while cloud runtime validation prefers the split contract.

   Alternative considered: store a canonical full `DATABASE_URL` in Secret Manager. That would be simpler for backend parsing, but it makes secret rotation and non-secret infrastructure outputs harder to reason about and conflicts with the password-only decision in the Phase 5 task list.

2. Keep password payload creation out of Terraform defaults unless an operator supplies it through secret payload inputs.

   The Cloud SQL module can create the database user only when a password value is provided through a sensitive variable or a generated-password path is explicitly implemented. The environment roots should avoid committed password values and wire Cloud Run `DB_PASSWORD` to the Secret Manager secret contract. This keeps plans useful while preventing accidental plaintext credentials.

   Alternative considered: generate the password with Terraform and write it to Secret Manager. That may be viable, but it introduces state-held secret material and needs an explicit rotation story. This proposal leaves room for implementation to use a sensitive input and Secret Manager reference without requiring committed values.

3. Make deletion protection stricter for prod than rc.

   Prod Cloud SQL deletion protection should default on. RC may allow deletion protection to be disabled for clean-state validation and cost-control workflows. Both environments remain explicitly gated by `module_activation.cloudsql`.

   Alternative considered: use the same deletion-protection default everywhere. That reduces drift, but it makes RC validation and future suspend/resume work clumsier.

4. Treat backend implementation as a coordinated apply slice, not a separate spec repo change.

   The spec is authored in `platform-infra`, and the apply task list assigns backend code ownership explicitly. This keeps the P5-T06 acceptance criteria testable end to end while respecting that `backend-api` owns runtime parsing and migration command behavior.

## Risks / Trade-offs

- Secret material in Terraform state -> avoid committed values, document any sensitive inputs, and prefer Secret Manager runtime delivery.
- Cloud SQL user creation needs a password -> gate user creation on a supplied sensitive password or an explicitly documented generation approach.
- Backend local compatibility regression -> preserve `DATABASE_URL` for local/test flows while adding split DB env support.
- Cross-repo implementation drift -> assign backend tasks with clear ownership and validate both repos before considering P5-T06 complete.
- Disabled-by-default modules can mask integration mistakes -> include module-level validation and enabled-plan checks for both `rc` and `prod`.

## Migration Plan

1. Update `platform-infra` Cloud SQL, secrets, environment root wiring, outputs, and docs.
2. Update `backend-api` config and migration entrypoints to build a DSN from split DB variables or accept local `DATABASE_URL`.
3. Validate Terraform with default-disabled roots and Cloud SQL/secrets/Cloud Run enabled plans for `rc` and `prod`.
4. Validate backend config tests and Go tests.
5. For actual environment rollout, seed the `api-db-password` secret value outside committed files before enabling Cloud Run against Cloud SQL.
