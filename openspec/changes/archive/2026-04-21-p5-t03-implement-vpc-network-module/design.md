## Context

`platform-infra` already has separate `rc` and `prod` Terraform roots and a skeletal `modules/network` module. P5-T03 turns that skeleton into the network contract consumed by Cloud SQL private IP, the Cloud Run API baseline, and the optional GKE Autopilot path. The implementation must preserve explicit per-environment root selection, separate projects, the `us-east4` regional baseline, and disabled-by-default resource creation in `terraform.tfvars` until rollout sequencing enables applies.

## Goals / Non-Goals

**Goals:**
- Provide one environment-scoped VPC per root with explicit subnet CIDR inputs.
- Enable private IP prerequisites for Google-managed services through private service access.
- Keep subnet settings compatible with Cloud SQL private IP, Cloud Run private egress wiring, and future GKE Autopilot attachment.
- Export stable network identifiers for downstream modules and environment-root outputs.
- Keep validation runnable through the existing Make targets.

**Non-Goals:**
- Provision Cloud Run service egress settings or Cloud SQL instances; those remain in P5-T04 and P5-T06.
- Create or activate a GKE cluster; P5-T13 owns the optional cluster module details.
- Change the remote state backend or environment topology established by P5-T02.
- Introduce shared VPC host/service project topology unless a future ADR requires it.

## Decisions

1. Use one standalone custom-mode VPC per environment project.
   - Rationale: the current platform model requires full `rc`/`prod` separation and one Terraform root per environment. A per-project VPC keeps the module easy to reason about and avoids shared VPC IAM complexity before a team/multi-project need exists.
   - Alternative considered: a central shared VPC host project. This was deferred because it adds cross-project IAM and lifecycle coupling without being required for the current baseline.

2. Keep subnet creation explicit and regional.
   - Rationale: `rc` and `prod` already define separate CIDRs and the platform standard locks `us-east4` as the primary region. Explicit subnet inputs make CIDR review visible in each environment root.
   - Alternative considered: module-generated CIDRs. This was rejected because deterministic environment-owned CIDRs are easier to audit and safer for future peering or VPN choices.

3. Manage private service access in the network module.
   - Rationale: Cloud SQL private IP depends on the reserved peering range and service networking connection before database creation. Keeping those prerequisites in the network module gives downstream modules a simple "network is ready" contract.
   - Alternative considered: place private service access in the Cloud SQL module. This would hide a shared network concern inside a database module and make GKE or other Google-managed-service consumers depend on Cloud SQL internals.

4. Expose identifiers, not provider implementation details.
   - Rationale: downstream modules need network and subnet self links/names plus the private service access range/connection. Stable outputs allow Cloud Run, Cloud SQL, and GKE modules to consume the network without duplicating resource addressing.
   - Alternative considered: pass entire resource objects through outputs. This would make module boundaries brittle and couple consumers to provider schema changes.

5. Keep module activation explicit.
   - Rationale: existing `module_activation.network` gates let plan/validate run while real applies wait for backend, IAM, and rollout approval. P5-T03 should not implicitly create cloud resources during unrelated validation.
   - Alternative considered: always create the network. This was rejected because it bypasses the repository's current rollout controls.

## Risks / Trade-offs

- Private service access lifecycle ordering fails or races Cloud SQL creation -> expose the PSA connection output and wire dependent modules so Terraform can infer creation order where needed.
- CIDR choices later conflict with peering or temporary project environments -> keep CIDR inputs explicit in environment `terraform.tfvars` and document any future changes before apply.
- Cloud Run private connectivity needs additional service-level egress configuration -> leave the Cloud Run service wiring to P5-T04 while providing network and subnet outputs needed by that work.
- Labels are not uniformly supported on all Compute networking resources -> apply labels only to resources that support them and keep naming/environment separation as the primary audit signal for unsupported resources.
