## ADDED Requirements

### Requirement: Dedicated RC Terraform apply workflow

`platform-infra` SHALL provide a dedicated GitHub Actions workflow that applies
Terraform for the RC environment only.

#### Scenario: Approved RC apply is started

- **WHEN** an operator starts the approved RC apply workflow from the allowed
  repository ref
- **THEN** the workflow MUST run Terraform against `environments/rc` only.

#### Scenario: Non-RC target is attempted

- **WHEN** the workflow is invoked with inputs or configuration that would
  target an environment other than `rc`
- **THEN** the workflow MUST fail before Terraform apply begins.

### Requirement: RC apply uses federated CI identity

The RC apply workflow SHALL authenticate to GCP and Terraform remote state
using GitHub OIDC and workload identity rather than long-lived static
credentials.

#### Scenario: Workflow authenticates to RC infrastructure

- **WHEN** the RC apply workflow runs
- **THEN** it MUST obtain credentials through the configured workload identity
  path with access scoped to the RC service project and its remote state
  backend.

### Requirement: RC apply preserves plan visibility

The RC apply workflow SHALL make the Terraform plan visible to operators before
or alongside the apply step and preserve plan/apply execution evidence.

#### Scenario: Operator reviews RC infrastructure changes

- **WHEN** the workflow prepares to apply RC Terraform changes
- **THEN** it MUST publish a readable Terraform plan summary or artifact for the
  resolved commit and preserve apply logs for later review.

### Requirement: RC apply enforces concurrency and state-lock conventions

The RC apply workflow SHALL prevent overlapping RC applies and SHALL preserve
the repository Terraform lock timeout convention.

#### Scenario: Another RC apply is already running

- **WHEN** a second RC apply workflow run is started while one is in progress
- **THEN** GitHub Actions concurrency controls MUST prevent overlapping applies
  for the RC environment.

#### Scenario: Terraform state is temporarily locked

- **WHEN** the workflow runs Terraform plan or apply for RC
- **THEN** it MUST use the repository lock-timeout convention before failing on
  backend lock contention.

### Requirement: RC apply has a documented operator contract

The RC apply path SHALL document who may trigger it, what branch or event gate
applies, what approval step is required, and how operators should recover from
failed or incorrect RC applies.

#### Scenario: Operator needs to run or recover RC apply

- **WHEN** an operator consults the RC deployment guidance
- **THEN** the documentation MUST describe trigger rules, approval expectations,
  plan visibility, rollback posture, and the relationship to the RC clean-state
  validation runbook.
