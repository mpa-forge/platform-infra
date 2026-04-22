## ADDED Requirements

### Requirement: Runtime modules consume network outputs by contract
Downstream runtime modules SHALL consume network identifiers from
`terraform-network-baseline` outputs instead of directly referencing
network-module resources.

#### Scenario: Cloud Run baseline depends on networked services
- **WHEN** the Cloud Run API environment binding attaches to Cloud SQL or other
  network-dependent services
- **THEN** it MUST consume downstream service connection outputs that were
  derived from the network module's VPC and private-service-access contract,
  not direct network resource references.
