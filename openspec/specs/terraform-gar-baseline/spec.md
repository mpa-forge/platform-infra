# terraform-gar-baseline Specification

## Purpose
TBD - created by archiving change p5-t05-gar-module-iam-bindings. Update Purpose after archive.
## Requirements
### Requirement: Regional minimal GAR repositories
The Terraform GAR module SHALL create only the explicitly configured regional
Artifact Registry repositories for the selected environment project.

#### Scenario: GAR module is enabled
- **WHEN** an environment root sets `module_activation.gar` to `true`
- **THEN** Terraform MUST create the configured Docker repositories in that
  environment's project and configured region.

#### Scenario: GAR module is disabled
- **WHEN** an environment root sets `module_activation.gar` to `false`
- **THEN** Terraform MUST NOT create Artifact Registry repositories or
  repository IAM bindings for that environment.

### Requirement: Baseline repository set
The environment roots SHALL configure the baseline GAR repository set as
`apps`, `workers`, and `tools` unless a later OpenSpec change or ADR expands
the set.

#### Scenario: Environment repositories are planned
- **WHEN** `rc` or `prod` plans with GAR enabled
- **THEN** the plan MUST include only `apps`, `workers`, and `tools` repository
  ids for the baseline set.

### Requirement: Repository cleanup policy
Each GAR repository SHALL include cleanup policy that prunes untagged artifacts
and old immutable SHA-tagged images while retaining a configurable number of
recent SHA-tagged images.

#### Scenario: Untagged artifacts age out
- **WHEN** an artifact has no tags and is older than the configured untagged
  retention duration
- **THEN** Artifact Registry cleanup policy MUST be configured to delete it.

#### Scenario: Old SHA images age out
- **WHEN** an image version is tagged with the configured immutable SHA tag
  prefix and is older than the configured tagged retention duration
- **THEN** Artifact Registry cleanup policy MUST be configured to delete it
  unless it is protected by the configured most-recent keep count.

### Requirement: Immutable image URI contract
The GAR module SHALL export repository URIs and expected immutable image URI
prefixes so CI and deployment tasks can reference regional repositories without
hard-coding project or region values.

#### Scenario: Downstream workflow needs an image URI
- **WHEN** CI builds `backend-api`, `backend-worker`, or `platform-ai-workers`
- **THEN** it MUST be able to derive a URI matching
  `${region}-docker.pkg.dev/${project_id}/${repository}/${image_name}:sha-<git_sha_12>`
  from GAR outputs and naming standards.

### Requirement: Repository-scoped IAM split
The GAR module SHALL grant repository-scoped writer permissions to configured
CI principals and repository-scoped reader permissions to configured runtime
principals.

#### Scenario: CI push principal is configured
- **WHEN** a repository includes a CI push member
- **THEN** Terraform MUST grant that member `roles/artifactregistry.writer` on
  that repository only.

#### Scenario: Runtime pull principal is configured
- **WHEN** a repository includes a runtime pull member
- **THEN** Terraform MUST grant that member `roles/artifactregistry.reader` on
  that repository only.

### Requirement: Environment-separated artifact boundaries
`rc` and `prod` GAR repositories SHALL remain isolated by project and root path,
and image duplication between environments MUST happen only through an explicit
promotion workflow or later approved change.

#### Scenario: RC and prod repositories are planned separately
- **WHEN** `make terraform-plan ENV=rc` and `make terraform-plan ENV=prod` run
  with GAR enabled
- **THEN** each plan MUST target only that environment's project id, regional
  repository ids, IAM members, and cleanup policy settings.

