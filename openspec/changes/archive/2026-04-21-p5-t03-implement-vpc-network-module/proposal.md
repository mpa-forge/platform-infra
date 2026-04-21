## Why

Phase 5 needs a concrete network baseline before Cloud SQL, Cloud Run API connectivity, and the optional GKE path can be applied reliably. The current skeleton establishes the shape, but P5-T03 should lock the VPC, subnet, private service access, routing, and downstream output contract that later runtime and database modules consume.

## What Changes

- Complete the Terraform network module contract for environment-scoped VPC creation in `rc` and `prod`.
- Define private subnet behavior for Cloud Run-to-Cloud SQL private connectivity and future GKE Autopilot attachment.
- Manage private service access for Google-managed services used by Cloud SQL private IP.
- Expose stable downstream outputs for network, subnetwork, and private service access resources.
- Preserve explicit per-environment enablement and separate project boundaries.

## Capabilities

### New Capabilities
- `terraform-network-baseline`: Defines the Terraform-managed VPC/network capability required by Cloud SQL, Cloud Run, and the optional GKE runtime path.

### Modified Capabilities
- None.

## Impact

- Affected code: `modules/network/**`, `environments/rc/**`, `environments/prod/**`, and any module inputs consuming network outputs.
- Affected systems: GCP VPC networking, regional subnetworks, private service access/service networking, Cloud SQL private IP prerequisites, and optional GKE Autopilot networking.
- Validation impact: `make terraform-validate`, `make terraform-plan ENV=rc`, and `make terraform-plan ENV=prod` should continue to work from the dedicated environment roots.
