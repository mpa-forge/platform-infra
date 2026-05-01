# platform-infra

Infrastructure-as-code repository for the platform blueprint.

## Structure

- `modules/`: reusable Terraform modules
- `environments/`: environment-specific Terraform roots
- `docs/`: infrastructure-specific documentation
- `scripts/`: local utility and developer scripts

## Toolchain

- GNU Make (or a compatible `make` implementation) and a bash-compatible shell
- Terraform `1.14.5`
- Version pin source: `.tool-versions` and `versions.tf`

## Setup

Before running bootstrap:

- Shared workspace requirement: keep `platform-blueprint-specs` checked out as a sibling directory if you want to use `make doctor`.
- Required: GNU Make (or a compatible `make` implementation) and a bash-compatible shell
- Recommended: `mise` or `asdf` for automatic tool installation from `.tool-versions`
- Fallback: manually install the pinned tool versions listed above

Run the setup commands from the repository root:

- Workstation checks: `make doctor`
- Bootstrap: `make bootstrap`

Bootstrap validates the pinned Terraform CLI version.
If `mise` or `asdf` is available, the script will use it to install the pinned toolchain automatically.

## Lint and Format

- Install git hooks: `make precommit-install`
- Run all pre-commit checks manually: `make precommit-run`
- Run Terraform formatting checks: `make repo-format-check`
- Run Terraform static analysis: `make repo-lint`
- Run Terraform validation: `make terraform-validate`
- Run repository policy checks: `make repo-policy-check`

The CI pipeline now runs the same formatting, lint, validation, and policy
checks on pull requests.

## Terraform Layout

Phase 5 now provides the initial Terraform repository skeleton:

- `environments/rc/`: explicit RC root with its own project boundary inputs
- `environments/prod/`: explicit prod root with its own project boundary inputs
- both roots now choose a `deployment_preset` while staying separate environments
- `modules/network/`: VPC, subnet, and private service access baseline
- `modules/cloudrun_api/`: Cloud Run API runtime baseline including the
  Phase 3 observability secret contract
- `modules/gar/`: Artifact Registry repositories and IAM binding scaffolding
- `modules/cloudsql/`: Cloud SQL PostgreSQL baseline
- `modules/grafana_dashboards/`: source-controlled Grafana folder and dashboard provisioning
- `modules/stack/`: shared environment assembly layer that derives module
  activation from deployment presets
- `modules/secrets/`: Secret Manager placeholders and IAM binding scaffolding
- `modules/gke/`: optional GKE Autopilot skeleton, disabled by default
- `modules/vps_stack/`: single-VM preset for low-cost frontend + backend +
  Postgres deployments
- `modules/observability_support/`: shared observability naming and env-contract
  outputs for Cloud Run and the optional GKE path

The repository keeps one Terraform root per environment and does not use
Terraform workspaces for environment switching.

Each root now selects a deployment preset instead of hand-toggling individual
modules. The current checked-in defaults are:

- `rc`: `cheap-single-vps`
- `prod`: `cloudrun-cloudsql`

Set `deployment_enabled=true` when you want the selected preset to create
resources; leaving it false keeps the topology selection explicit without
turning on infrastructure by default.

The Cloud Run API module now owns the baseline runtime contract: service
account, revision settings, startup env, Secret Manager-backed telemetry and
database password tokens, Cloud SQL socket attachment, ingress, optional invoker
policy, and exported service/runtime outputs. Default `terraform.tfvars` files
keep resource creation disabled until backend images, secret payloads, IAM, and
rollout sequencing are ready. This still lets us validate module/root contracts
and plan each environment from its dedicated root.

Repo-local Terraform entrypoints:

- `make terraform-validate`
- `make terraform-plan ENV=rc`
- `make terraform-plan ENV=prod`
- `make terraform-apply ENV=rc`
- `make terraform-apply ENV=prod`
- GitHub Actions manual RC apply: `terraform-apply-rc`

The environment roots use remote state in GCS. Real plan/apply workflows should
authenticate with ADC or a CI service account that has access to the matching
environment state bucket. For local runs, the Make targets can also use an
access token from the active `gcloud` account when ADC is not configured.

Observability secret-delivery expectations remain documented in
`docs/observability-secret-delivery.md`, and the Cloud Run module now turns that
contract into the baseline Terraform wiring shape for later rollout tasks.
Grafana dashboard provisioning now consumes the source-controlled dashboard JSON
under `docs/grafana-dashboards/` through the env roots and the
`modules/grafana_dashboards` module. Provide a Grafana API token either through
`TF_VAR_grafana_dashboard_provisioning_token` or by pointing
`grafana_dashboard_provisioning_token_secret_name` at a Secret Manager secret
that contains a write-capable dashboard provisioning token.
See `docs/terraform-file-guide.md` for a file-by-file explanation of the
Terraform layout.
See `docs/deployment-presets.md` for the preset catalog and activation model.
See `docs/module-cost-presets.md` for mix-and-match per-module cost tuning.
See `docs/terraform-remote-state.md` for the state project, bucket, IAM, and
operator workflow.
See `docs/runbooks/rc-terraform-apply.md` for the CI-managed RC apply contract.
See `docs/cloud-run-api-runtime.md` for the Phase 5 Cloud Run API runtime
contract.
See `docs/artifact-registry.md` for the regional GAR repository, cleanup, image
tag, and IAM contract.
See `docs/cloudsql-postgres.md` for the Cloud SQL PostgreSQL and password-only
database secret contract, including named cost profiles such as `super_cheap`,
`cheap_dev`, `rc`, and `prod`.

## Run

The repo does own the centralized Phase 1 local development stack:

- `make local-frontend-support-up` starts `postgres` + `backend-api`
- `make local-frontend-support-up BUILD=1` forces a rebuild before startup
- `make local-api-support-up` starts `postgres` + `frontend-web`
- `make local-api-support-up BUILD=1` forces a rebuild before startup
- `make local-full-up` starts `frontend-web` + `backend-api` + `postgres`
- `make local-smoke-test` starts the full stack, verifies health, and stops it
- `make local-db-reset` recreates the Postgres volume and reapplies the local seed baseline
- `make local-down` stops the stack

See `docs/local-development-stack.md` for the local development model and port map.
See `docs/observability-secret-delivery.md` for the Grafana OTLP secret
delivery contract that later Terraform and GKE modules will adopt.
The GKE placeholder set now includes:

- `docs/placeholders/gke/backend-api-otlp-external-secret.yaml`
- `docs/placeholders/gke/backend-api-observability-env.yaml`
- `docs/placeholders/gke/backend-api-collector-gateway.yaml`

## Test

Run the same baseline checks locally before pushing:

- `make repo-format-check`
- `make repo-lint`
- `make terraform-validate`
- `make repo-policy-check`
