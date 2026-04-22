# terraform-cloudsql-postgres Specification

## Purpose
Define the Cloud SQL PostgreSQL infrastructure baseline, including private
connectivity, environment-separated database resources, password-only runtime
secret delivery, and cost-control profiles for RC and production roots.

## Requirements
### Requirement: Gated Cloud SQL PostgreSQL instance

The Terraform Cloud SQL PostgreSQL module SHALL create a PostgreSQL instance in the selected environment project only when explicitly enabled by the environment root.

#### Scenario: Cloud SQL module is enabled

- **WHEN** an environment root sets `module_activation.cloudsql` to `true`
- **THEN** Terraform MUST manage one PostgreSQL instance in that environment project and configured region using the environment-specific instance name, labels, tier, storage, backup, and maintenance inputs.

#### Scenario: Cloud SQL module is disabled

- **WHEN** an environment root sets `module_activation.cloudsql` to `false`
- **THEN** Terraform MUST NOT create the PostgreSQL instance, application database, application user, IAM bindings, or other Cloud SQL resources for that environment.

### Requirement: Private network connectivity

The Cloud SQL PostgreSQL module SHALL use private IP connectivity through the network module private service access contract and SHALL avoid public IPv4 exposure for the baseline database.

#### Scenario: Private networking is configured

- **WHEN** the Cloud SQL module is enabled
- **THEN** the instance MUST use the VPC self link exported by the network module for private networking and MUST have public IPv4 disabled.

#### Scenario: Network prerequisite is enforced

- **WHEN** an environment root enables Cloud SQL
- **THEN** the root MUST require the network module to be enabled and MUST order Cloud SQL creation after the private service access connection is available.

### Requirement: Backup and maintenance baseline

The Cloud SQL PostgreSQL instance SHALL configure automated backups, point-in-time recovery, and an explicit maintenance window suitable for the selected environment.

#### Scenario: Instance backup settings are planned

- **WHEN** the Cloud SQL module is enabled
- **THEN** Terraform MUST configure automated backups and point-in-time recovery for the instance.

#### Scenario: Maintenance window is planned

- **WHEN** the Cloud SQL module is enabled
- **THEN** Terraform MUST configure the maintenance day, hour, and update track from module inputs.

### Requirement: Named Cloud SQL cost profiles

The `rc` and `prod` environment roots SHALL expose named Cloud SQL sizing
profiles so operators can switch between very low-cost development, comfortable
development, release-candidate, and production database postures without
rewiring module inputs.

#### Scenario: Super cheap profile is selected

- **WHEN** an environment root sets `cloudsql_profile` to `super_cheap`
- **THEN** Terraform MUST plan an Enterprise edition, zonal, HDD-backed,
  minimal-tier Cloud SQL instance with backups and point-in-time recovery
  disabled for cost control.

#### Scenario: Higher-cost profiles are selected

- **WHEN** an environment root sets `cloudsql_profile` to `cheap_dev`, `rc`, or
  `prod`
- **THEN** Terraform MUST derive the instance tier, availability type, disk
  type, storage size, backup, point-in-time recovery, and maintenance settings
  from that named profile.

#### Scenario: Environment defaults are cost controlled

- **WHEN** the committed `rc` or `prod` Terraform variable defaults are used
- **THEN** the selected Cloud SQL profile MUST be `super_cheap` until an
  operator intentionally promotes that environment to a more expensive profile.

### Requirement: Application database and user baseline

The Cloud SQL PostgreSQL module SHALL manage the API application database and an application database user without requiring a committed plaintext password in environment values.

#### Scenario: Application database is created

- **WHEN** the Cloud SQL module is enabled
- **THEN** Terraform MUST manage the configured API application database in the environment Cloud SQL instance.

#### Scenario: Application user password is provided securely

- **WHEN** Terraform creates or updates the API database user
- **THEN** the password value MUST come from a sensitive input, generated secret flow, or existing secret reference and MUST NOT be committed in `terraform.tfvars` or documentation examples as a real credential.

### Requirement: API database credential contract

The infrastructure contract SHALL expose non-secret database connection parts and a password-only Secret Manager reference for the API runtime instead of a canonical full connection string with embedded credentials.

#### Scenario: Cloud Run consumes database connection settings

- **WHEN** Cloud Run API is enabled with Cloud SQL
- **THEN** the environment root MUST provide `DB_HOST` or Cloud SQL socket path, `DB_NAME`, and `DB_USER` as plain environment variables and `DB_PASSWORD` as a Secret Manager-backed environment variable.

#### Scenario: Full database URL is not committed

- **WHEN** Terraform environment values, docs, or outputs describe the API database contract
- **THEN** they MUST NOT include a committed full database URL containing the application password.

### Requirement: Environment-separated database resources

The `rc` and `prod` database baselines SHALL remain isolated by project, root path, instance name, database name, user/credential contract, Secret Manager reference, IAM bindings, and deletion-protection settings.

#### Scenario: RC and prod plans are run separately

- **WHEN** `make terraform-plan ENV=rc` and `make terraform-plan ENV=prod` run from their dedicated roots
- **THEN** each plan MUST target only that environment's project id, database names, instance names, network, secrets, IAM members, and deletion-protection settings.

### Requirement: Downstream database outputs

The Cloud SQL PostgreSQL module and environment roots SHALL expose stable outputs for downstream runtime, migration, operations, and future GKE consumers.

#### Scenario: Runtime modules need database identifiers

- **WHEN** Cloud Run, optional GKE, or operational runbooks need database connection data
- **THEN** they MUST be able to consume the selected profile, edition, tier,
  instance name, instance connection name, database name, application user,
  socket path or host contract, and password secret name without referencing
  module-internal resources.
