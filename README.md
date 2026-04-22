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
- Run repo lint checks: `make lint`
- Formatting is deferred for the infra repo in the Phase 1 baseline

## Terraform Layout

Phase 5 now provides the initial Terraform repository skeleton:

- `environments/rc/`: explicit RC root with its own project boundary inputs
- `environments/prod/`: explicit prod root with its own project boundary inputs
- `modules/network/`: VPC, subnet, and private service access baseline
- `modules/cloudrun_api/`: Cloud Run API runtime baseline including the
  Phase 3 observability secret contract
- `modules/gar/`: Artifact Registry repositories and IAM binding scaffolding
- `modules/cloudsql/`: Cloud SQL PostgreSQL baseline
- `modules/secrets/`: Secret Manager placeholders and IAM binding scaffolding
- `modules/gke/`: optional GKE Autopilot skeleton, disabled by default
- `modules/observability_support/`: shared observability naming and env-contract
  outputs for Cloud Run and the optional GKE path

The repository keeps one Terraform root per environment and does not use
Terraform workspaces for environment switching.

The Cloud Run API module now owns the baseline runtime contract: service
account, revision settings, startup env, Secret Manager-backed telemetry token,
Cloud SQL socket attachment, ingress, optional invoker policy, and exported
service/runtime outputs. Default `terraform.tfvars` files keep resource creation
disabled until backend images, secret payloads, IAM, and rollout sequencing are
ready. This still lets us validate module/root contracts and plan each
environment from its dedicated root.

Repo-local Terraform entrypoints:

- `make terraform-validate`
- `make terraform-plan ENV=rc`
- `make terraform-plan ENV=prod`
- `make terraform-apply ENV=rc`
- `make terraform-apply ENV=prod`

The environment roots use remote state in GCS. Real plan/apply workflows should
authenticate with ADC or a CI service account that has access to the matching
environment state bucket. For local runs, the Make targets can also use an
access token from the active `gcloud` account when ADC is not configured.

Observability secret-delivery expectations remain documented in
`docs/observability-secret-delivery.md`, and the Cloud Run module now turns that
contract into the baseline Terraform wiring shape for later rollout tasks.
See `docs/terraform-file-guide.md` for a file-by-file explanation of the
Terraform layout.
See `docs/terraform-remote-state.md` for the state project, bucket, IAM, and
operator workflow.
See `docs/cloud-run-api-runtime.md` for the Phase 5 Cloud Run API runtime
contract.

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

No automated validation commands are configured yet.
Formatting, validation, and policy checks will be introduced incrementally in later tasks.
