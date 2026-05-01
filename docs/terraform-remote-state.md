# Terraform Remote State

`platform-infra` stores Terraform state in a dedicated Google Cloud project so
state is separate from the RC and prod runtime projects.

## State Project

- Project ID: `mpa-forge-bp-tfstate`
- Region: `us-east4`
- RC bucket: `gs://mpa-forge-bp-tfstate-rc`
- Prod bucket: `gs://mpa-forge-bp-tfstate-prod`

Each bucket has Object Versioning, Uniform bucket-level access, and Public
Access Prevention enabled.

## Backend Prefixes

- RC root: `rc/platform-infra`
- Prod root: `prod/platform-infra`

The environment roots define these values directly in their `backend "gcs"`
blocks. Terraform backend blocks do not read variables, so changing a bucket or
prefix requires editing the root and rerunning `terraform init -migrate-state`.

## IAM

Environment-specific state service accounts exist in the state project:

- RC: `tfstate-rc@mpa-forge-bp-tfstate.iam.gserviceaccount.com`
- Prod: `tfstate-prod@mpa-forge-bp-tfstate.iam.gserviceaccount.com`

Each service account is bound only to its matching bucket. Human maintainers may
also use Application Default Credentials when their account has state-bucket
access.

## Operator Workflow

Authenticate before planning or applying:

```sh
gcloud auth application-default login
```

Local Make targets can also use the active `gcloud` account's access token when
ADC is not configured.

Run plans and applies through the repo targets:

```sh
make terraform-plan ENV=rc
make terraform-apply ENV=rc
make terraform-plan ENV=prod
make terraform-apply ENV=prod
```

The plan and apply targets use `-lock-timeout=5m` so concurrent runs wait for
the shared GCS state lock instead of failing immediately.

## GitHub Actions RC Apply

`platform-infra` also exposes a manual GitHub Actions workflow,
`terraform-apply-rc`, that applies `environments/rc` only.

The workflow:

- authenticates through GitHub OIDC and Workload Identity Federation
- uses the same remote backend as local operator runs
- preserves the `-lock-timeout=5m` convention
- publishes plan and apply artifacts for review
- gates the final apply step behind the `rc-apply` GitHub Environment

Required repository variables:

- `RC_GCP_WORKLOAD_IDENTITY_PROVIDER`
- `RC_GCP_CI_SERVICE_ACCOUNT`

See [docs/runbooks/rc-terraform-apply.md](/C:/Users/Miquel/dev/platform-infra/docs/runbooks/rc-terraform-apply.md)
for the full operator contract.
