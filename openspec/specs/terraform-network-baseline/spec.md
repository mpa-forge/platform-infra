# terraform-network-baseline Specification

## Purpose
TBD - created by archiving change p5-t03-implement-vpc-network-module. Update Purpose after archive.
## Requirements
### Requirement: Environment-scoped custom VPC
The Terraform network module SHALL create a custom-mode VPC in the environment project only when the environment root explicitly enables the network module.

#### Scenario: Network module is enabled
- **WHEN** an environment root sets `module_activation.network` to `true`
- **THEN** Terraform manages a custom-mode VPC using that environment's project id and configured network name.

#### Scenario: Network module is disabled
- **WHEN** an environment root sets `module_activation.network` to `false`
- **THEN** Terraform MUST NOT create VPC, subnet, private service access, or route resources for that environment.

### Requirement: Regional private subnet baseline
The Terraform network module SHALL create a regional primary subnet with private Google access enabled and an explicit environment-owned CIDR block.

#### Scenario: Primary subnet is created
- **WHEN** the network module is enabled for `rc` or `prod`
- **THEN** Terraform manages a primary subnet in the configured region using the configured subnet name and CIDR block.

#### Scenario: Google APIs are reached privately from subnet workloads
- **WHEN** workloads attached to the primary subnet call supported Google APIs
- **THEN** the subnet MUST have private Google access enabled.

### Requirement: Private service access for managed services
The Terraform network module SHALL reserve an internal VPC peering range and establish private service access with `servicenetworking.googleapis.com` for Google-managed services such as Cloud SQL private IP.

#### Scenario: Private service access is created
- **WHEN** the network module is enabled
- **THEN** Terraform manages a reserved private service access range and service networking connection for the environment VPC.

#### Scenario: Cloud SQL consumes private networking
- **WHEN** the Cloud SQL module receives the network module's VPC output
- **THEN** the private service access resources MUST be available for Cloud SQL private IP provisioning.

### Requirement: Downstream network outputs
The Terraform network module SHALL expose stable outputs that downstream modules can consume without directly referencing module-internal resources.

#### Scenario: Runtime and database modules consume network identifiers
- **WHEN** Cloud SQL, Cloud Run, or GKE modules need network attachment inputs
- **THEN** the network module MUST output the VPC name, VPC self link, subnet name, subnet self link, and private service access range name.

#### Scenario: Disabled module outputs remain safe
- **WHEN** the network module is disabled
- **THEN** network outputs MUST resolve to null-compatible values that allow validation of disabled downstream modules.

### Requirement: Environment separation
The Terraform network implementation SHALL keep `rc` and `prod` network resources isolated by project, root path, names, and CIDR inputs.

#### Scenario: RC and prod are planned separately
- **WHEN** `make terraform-plan ENV=rc` and `make terraform-plan ENV=prod` run from their dedicated roots
- **THEN** each plan MUST target only that environment's project id, network names, and subnet CIDR settings.

### Requirement: Terraform validation compatibility
The network implementation SHALL remain compatible with the repository's Terraform validation and plan entrypoints.

#### Scenario: Terraform validation runs
- **WHEN** `make terraform-validate` is executed
- **THEN** the network module and both environment roots MUST validate successfully.

#### Scenario: Environment plans run
- **WHEN** `make terraform-plan ENV=rc` or `make terraform-plan ENV=prod` is executed with valid credentials and backend access
- **THEN** Terraform MUST be able to plan the network resources from the selected root without workspace-based environment switching.
