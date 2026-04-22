## ADDED Requirements

### Requirement: Explicit Cloud Run API runtime resource
The Terraform Cloud Run API module SHALL create one Cloud Run v2 service and
one runtime service account in the selected environment project only when the
module is explicitly enabled.

#### Scenario: Cloud Run API module is enabled
- **WHEN** an environment root sets `module_activation.cloudrun_api` to `true`
- **THEN** Terraform manages the API Cloud Run service, runtime service
  account, revision template, labels, and configured service-level ingress in
  that environment project.

#### Scenario: Cloud Run API module is disabled
- **WHEN** an environment root sets `module_activation.cloudrun_api` to `false`
- **THEN** Terraform MUST NOT create the Cloud Run service, runtime service
  account, invoker binding, or runtime IAM bindings for that environment.

### Requirement: Backend API startup environment contract
The Cloud Run API service SHALL receive the required backend startup
environment variables for the Cloud Run baseline, including application
environment, log level, HTTP port, database URL, auth issuer, auth audience,
runtime path, direct OTLP mode, telemetry profile, OTLP endpoint, Grafana
instance ID, and Grafana ingest token reference.

#### Scenario: Environment root composes startup variables
- **WHEN** the `rc` or `prod` root instantiates the Cloud Run API module
- **THEN** the root MUST pass plain and secret-backed environment variables
  matching the backend API startup contract for the selected environment.

#### Scenario: Grafana token uses Secret Manager
- **WHEN** the Cloud Run API service is enabled
- **THEN** `GRAFANA_OTLP_INGEST_TOKEN` MUST be injected from Secret Manager and
  the runtime service account MUST be granted secret accessor permission for
  that secret.

### Requirement: Runtime revision controls
The Cloud Run API module SHALL expose revision-level controls for container
image, port, CPU and memory limits, startup probe, timeout, min instances, max
instances, request concurrency, and launch-stage annotations.

#### Scenario: Revision template is planned
- **WHEN** Terraform plans the Cloud Run API service
- **THEN** the revision template MUST include the configured image, port,
  scaling, concurrency, timeout, resources, labels, annotations, and startup
  probe values.

### Requirement: Cloud SQL attachment contract
The Cloud Run API module SHALL support Cloud SQL connectivity by mounting
configured instance connection names and granting the runtime service account
Cloud SQL client permissions when Cloud SQL is attached.

#### Scenario: Cloud SQL connection is provided
- **WHEN** the module receives one or more Cloud SQL instance connection names
- **THEN** Terraform MUST configure the Cloud Run Cloud SQL volume attachment
  and grant `roles/cloudsql.client` to the runtime service account.

#### Scenario: Cloud SQL connection is absent
- **WHEN** no Cloud SQL instance connection names are provided
- **THEN** Terraform MUST omit the Cloud SQL volume attachment and Cloud SQL
  client binding while preserving validation compatibility.

### Requirement: Controlled invocation and ingress
The Cloud Run API service SHALL default to internal/load-balancer ingress and
MUST grant public unauthenticated invocation only when the environment root
explicitly enables that behavior.

#### Scenario: Public invocation remains disabled by default
- **WHEN** the environment root uses default Cloud Run API settings
- **THEN** Terraform MUST NOT grant `roles/run.invoker` to `allUsers`.

#### Scenario: Public invocation is explicitly enabled
- **WHEN** the environment root sets the public invocation flag to `true`
- **THEN** Terraform MUST grant `roles/run.invoker` to `allUsers` for that
  service.

### Requirement: Environment-separated Cloud Run bindings
The `rc` and `prod` roots SHALL pass environment-specific project ids, service
names, service-account ids, labels, auth values, database names, and scaling
inputs to the shared Cloud Run API module.

#### Scenario: RC and prod roots are planned separately
- **WHEN** `make terraform-plan ENV=rc` and `make terraform-plan ENV=prod` run
  from their dedicated roots
- **THEN** each plan MUST target only that environment's project id, Cloud Run
  service name, service account id, runtime env values, and configured image.

### Requirement: Downstream Cloud Run outputs
The Cloud Run API module and environment roots SHALL expose stable outputs for
service name, service URI, runtime service account email, runtime path, and
Cloud SQL attachment contract.

#### Scenario: Routing and deployment tasks consume outputs
- **WHEN** later routing, deployment, or runtime-switch tasks need Cloud Run
  identifiers
- **THEN** they MUST be able to read the service identity and runtime contract
  from module or root outputs without referencing module-internal resources.
