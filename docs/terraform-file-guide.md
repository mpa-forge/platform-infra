# Terraform File Guide

This document explains what each Terraform `.tf` file in `platform-infra` is
for, and how the files fit together.

## How To Read The Repo

The Terraform layout follows one root per environment:

- `environments/rc/` is the RC root
- `environments/prod/` is the prod root
- `modules/*/` contains reusable building blocks shared by both environments

The roots now select a deployment preset instead of directly exposing a
per-module activation object.

Within each root or module, the file split is intentional:

- `versions.tf`: Terraform and provider version requirements
- `providers.tf`: provider configuration for a root module
- `variables.tf`: input contract for that root or module
- `main.tf`: resources, locals, and module wiring
- `outputs.tf`: values exported for downstream wiring or operator visibility

## Repo Root

### `versions.tf`

Path: [versions.tf](../versions.tf)

Pins the Terraform CLI version for the repository at `1.14.5`.
This is the repo-wide baseline that keeps local runs, CI, and environment roots
on the same Terraform version.

## Environment Roots

The environment roots are the deploy entrypoints. You run `terraform init`,
`terraform validate`, and `terraform plan` from these directories rather than
switching environments with Terraform workspaces.

### RC Root

#### `environments/rc/versions.tf`

Path: [environments/rc/versions.tf](../environments/rc/versions.tf)

Pins Terraform and the `hashicorp/google` provider for the RC root.
This makes the RC root self-contained and explicit about the provider contract
it expects.
It also configures the RC `backend "gcs"` block, storing state in
`gs://mpa-forge-bp-tfstate-rc/rc/platform-infra`.

#### `environments/rc/providers.tf`

Path: [environments/rc/providers.tf](../environments/rc/providers.tf)

Configures the Google provider for the RC service project and region.
This is where the root decides which GCP project the shared modules should
operate against.

#### `environments/rc/variables.tf`

Path: [environments/rc/variables.tf](../environments/rc/variables.tf)

Defines the RC root's input contract:

- project and state-project boundaries
- region defaults
- deployment preset selection and activation
- per-module cost preset selection
- network naming inputs
- API image reference, auth inputs, port, scaling, and invocation controls
- single-VPS sizing and ingress defaults
- API database user and password secret naming
- Cloud SQL cost and durability profile selection
- observability inputs

This file answers "what must be supplied to compose the RC environment?"

#### `environments/rc/main.tf`

Path: [environments/rc/main.tf](../environments/rc/main.tf)

Composes the RC environment by:

- calling the shared `modules/stack` assembly layer
- selecting the active deployment preset for RC
- forwarding environment-specific inputs into the shared stack contract

This is the actual environment assembly file.

#### `environments/rc/outputs.tf`

Path: [environments/rc/outputs.tf](../environments/rc/outputs.tf)

Exports the RC root's high-level contract, including:

- project-boundary information
- preset-aware deployment status
- important service-facing outputs such as the Grafana token secret name and
  Cloud SQL connection name
- normalized frontend, backend, database, and operational contracts

This file is mainly for visibility and downstream integration.

### Prod Root

The prod root mirrors the RC root so both environments stay structurally
consistent while remaining fully separate.

#### `environments/prod/versions.tf`

Path: [environments/prod/versions.tf](../environments/prod/versions.tf)

Pins Terraform and the Google provider for the prod root.
It also configures the prod `backend "gcs"` block, storing state in
`gs://mpa-forge-bp-tfstate-prod/prod/platform-infra`.

#### `environments/prod/providers.tf`

Path: [environments/prod/providers.tf](../environments/prod/providers.tf)

Configures the Google provider for the prod project and region.

#### `environments/prod/variables.tf`

Path: [environments/prod/variables.tf](../environments/prod/variables.tf)

Defines the prod root input contract, matching the RC root but targeting prod
project boundaries and prod-specific values.

#### `environments/prod/main.tf`

Path: [environments/prod/main.tf](../environments/prod/main.tf)

Composes the prod environment from the shared modules, with the same baseline
shape as RC:

- the same shared stack module
- a prod-specific preset default
- the same normalized output shape

This symmetry reduces drift between RC and prod.

#### `environments/prod/outputs.tf`

Path: [environments/prod/outputs.tf](../environments/prod/outputs.tf)

Exports the prod root's boundary and service contract values.

## Shared Modules

Each module owns one infrastructure concern. The environment roots decide
whether to use them and what values to pass in.

### `modules/network/*`

#### `modules/network/versions.tf`

Path: [modules/network/versions.tf](../modules/network/versions.tf)

Pins Terraform and the Google provider for the network module.

#### `modules/network/variables.tf`

Path: [modules/network/variables.tf](../modules/network/variables.tf)

Defines the network module inputs such as:

- target project and region
- VPC and subnet names
- subnet CIDR
- private service access range settings
- labels

#### `modules/network/main.tf`

Path: [modules/network/main.tf](../modules/network/main.tf)

Creates the VPC baseline:

- a custom-mode VPC
- the primary subnet
- the reserved private service access range
- the service networking connection needed by Google-managed private services

This module exists so Cloud SQL and the optional GKE path can share one network
contract.

#### `modules/network/outputs.tf`

Path: [modules/network/outputs.tf](../modules/network/outputs.tf)

Exports the network identifiers other modules need, such as the VPC and subnet
self-links, plus the private service access range and connection identifier
used for downstream dependency ordering.

### `modules/cloudrun_api/*`

#### `modules/cloudrun_api/versions.tf`

Path: [modules/cloudrun_api/versions.tf](../modules/cloudrun_api/versions.tf)

Pins Terraform and the Google provider for the Cloud Run API module.

#### `modules/cloudrun_api/variables.tf`

Path: [modules/cloudrun_api/variables.tf](../modules/cloudrun_api/variables.tf)

Defines the Cloud Run API module inputs, including:

- service identity and image reference
- scaling and concurrency controls
- ingress, launch-stage, and public invocation controls
- container port and startup probe settings
- plain env vars
- secret-backed env vars
- optional Cloud SQL connection names

#### `modules/cloudrun_api/main.tf`

Path: [modules/cloudrun_api/main.tf](../modules/cloudrun_api/main.tf)

Implements the baseline API runtime on Cloud Run by creating:

- the runtime service account
- Cloud SQL client IAM when Cloud SQL is attached
- secret access IAM for runtime secrets
- an optional unauthenticated invoker binding when explicitly enabled
- the Cloud Run v2 service itself

This is where the documented observability env and secret contract becomes real
Terraform wiring. It also mounts Cloud SQL sockets at `/cloudsql` when the
environment root provides instance connection names.

#### `modules/cloudrun_api/outputs.tf`

Path: [modules/cloudrun_api/outputs.tf](../modules/cloudrun_api/outputs.tf)

Exports service identity and endpoint details, such as the service name, URI,
runtime service account email, and the Cloud Run runtime contract consumed by
later deployment, routing, and runtime-switch tasks.

### `modules/cloudsql/*`

#### `modules/cloudsql/versions.tf`

Path: [modules/cloudsql/versions.tf](../modules/cloudsql/versions.tf)

Pins Terraform and the Google provider for the Cloud SQL module.

#### `modules/cloudsql/variables.tf`

Path: [modules/cloudsql/variables.tf](../modules/cloudsql/variables.tf)

Defines the database module inputs:

- instance and database naming
- application database user naming
- region and network attachment
- tier and availability defaults
- maintenance window
- labels and deletion protection

#### `modules/cloudsql/main.tf`

Path: [modules/cloudsql/main.tf](../modules/cloudsql/main.tf)

Creates the PostgreSQL baseline:

- a Cloud SQL PostgreSQL instance
- the configured Cloud SQL edition and machine tier
- backups and point-in-time recovery
- private-IP networking
- the primary application database
- the API application user when the sensitive password input is provided

#### `modules/cloudsql/outputs.tf`

Path: [modules/cloudsql/outputs.tf](../modules/cloudsql/outputs.tf)

Exports the instance name, connection name, database name, database user, and
socket path for consumers such as Cloud Run.

### `modules/gar/*`

#### `modules/gar/versions.tf`

Path: [modules/gar/versions.tf](../modules/gar/versions.tf)

Pins Terraform and the Google provider for Artifact Registry resources.

#### `modules/gar/variables.tf`

Path: [modules/gar/variables.tf](../modules/gar/variables.tf)

Defines the GAR input contract:

- project and region
- labels
- repository definitions
- expected image names per repository
- cleanup policy definitions
- CI push members
- runtime pull members

#### `modules/gar/main.tf`

Path: [modules/gar/main.tf](../modules/gar/main.tf)

Creates Artifact Registry repositories and flattens IAM bindings so CI and
runtime principals can be granted least-privilege access per repository. Each
repository also receives cleanup policy so untagged artifacts and old SHA-tagged
images do not accumulate indefinitely.

#### `modules/gar/outputs.tf`

Path: [modules/gar/outputs.tf](../modules/gar/outputs.tf)

Exports the created repository IDs, regional repository URI prefixes, and
expected immutable image URI prefixes keyed by logical repository/image names.

### `modules/secrets/*`

#### `modules/secrets/versions.tf`

Path: [modules/secrets/versions.tf](../modules/secrets/versions.tf)

Pins Terraform and the Google provider for Secret Manager resources.

#### `modules/secrets/variables.tf`

Path: [modules/secrets/variables.tf](../modules/secrets/variables.tf)

Defines the secret module input contract:

- secret IDs
- accessor principals
- labels
- metadata annotations

#### `modules/secrets/main.tf`

Path: [modules/secrets/main.tf](../modules/secrets/main.tf)

Creates Secret Manager secret placeholders and assigns secret accessor IAM to
the listed principals.

This module owns the existence and access policy of the secret, not the secret
payload value itself.

#### `modules/secrets/outputs.tf`

Path: [modules/secrets/outputs.tf](../modules/secrets/outputs.tf)

Exports the resulting secret IDs and resource names keyed by logical name.

### `modules/stack/*`

The shared stack module is now the environment composition layer. It:

- maps `deployment_preset` to module activation
- applies module-level cost presets such as VPS sizing, Cloud Run scaling,
  Artifact Registry retention, and Secret Manager footprint
- keeps environment policy separate from runtime topology
- assembles the shared service, database, networking, and operational outputs
- preserves one root per environment while removing duplicated root assembly

### `modules/vps_stack/*`

This module implements the first low-cost preset:

- one VM
- optional static or ephemeral public IP
- firewall rules for app and SSH access
- startup metadata/script hooks
- output contracts for frontend, backend, and localhost database access

### `modules/gke/*`

#### `modules/gke/versions.tf`

Path: [modules/gke/versions.tf](../modules/gke/versions.tf)

Pins Terraform and the Google provider for the optional GKE module.

#### `modules/gke/variables.tf`

Path: [modules/gke/variables.tf](../modules/gke/variables.tf)

Defines the optional GKE module inputs, including:

- project and region
- cluster name
- network and subnet attachment
- release channel
- labels
- deletion protection

#### `modules/gke/main.tf`

Path: [modules/gke/main.tf](../modules/gke/main.tf)

Creates the optional Autopilot cluster with workload identity enabled.
This module exists so the later runtime switch to GKE can happen without
restructuring the environment roots.

#### `modules/gke/outputs.tf`

Path: [modules/gke/outputs.tf](../modules/gke/outputs.tf)

Exports cluster details such as the cluster name and control-plane endpoint.

### `modules/observability_support/*`

#### `modules/observability_support/versions.tf`

Path: [modules/observability_support/versions.tf](../modules/observability_support/versions.tf)

Pins Terraform for the local-only helper module.
This module does not currently need a provider because it computes shared values
rather than creating infrastructure directly.

#### `modules/observability_support/variables.tf`

Path: [modules/observability_support/variables.tf](../modules/observability_support/variables.tf)

Defines the observability contract inputs:

- environment name
- telemetry profile
- Grafana instance ID
- direct OTLP endpoint
- collector OTLP endpoint

#### `modules/observability_support/main.tf`

Path: [modules/observability_support/main.tf](../modules/observability_support/main.tf)

Builds the shared naming and env-var maps for observability, including:

- the Grafana token secret name
- Cloud Run env vars for direct OTLP mode
- GKE env vars for collector-gateway mode

This module keeps the observability contract consistent across runtime paths.

#### `modules/observability_support/outputs.tf`

Path: [modules/observability_support/outputs.tf](../modules/observability_support/outputs.tf)

Exports the secret name and the env-var maps that other modules consume.

## Why Some Files Look Repeated

You will notice that `rc` and `prod` have near-identical file sets, and every
module has the same `versions.tf` / `variables.tf` / `main.tf` / `outputs.tf`
pattern.

That repetition is deliberate:

- roots stay explicit and independently plannable
- module contracts stay easy to scan
- environment selection stays tied to directory path, not hidden workspace state
- preset selection stays explicit without multiplying root directories
- future tasks can extend one concern at a time without mixing contracts,
  providers, resources, and outputs into one large file

## What Is Not Here Yet

This Phase 5 baseline intentionally does not yet include:

- AI worker Cloud Run Jobs and Scheduler resources
- edge routing for `/api/*`
- Grafana dashboard provisioning resources

The repository does already include the baseline CI formatting, validation,
lint, and policy checks introduced in P5-T10. Later tasks may still extend the
policy engine or add deeper plan-time enforcement.

Those land in later Phase 5 tasks on top of this file and module structure.
