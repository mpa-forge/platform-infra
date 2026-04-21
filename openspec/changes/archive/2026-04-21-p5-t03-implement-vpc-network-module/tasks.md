## 1. Network Module Contract

- [x] 1.1 Review `modules/network/**`, `environments/rc/**`, and `environments/prod/**` against the `terraform-network-baseline` spec.
  Sub-agent: None
  Ownership: Local review and implementation planning
  Blocking: Yes - establishes the exact patch scope.
- [x] 1.2 Update `modules/network` variables and resources to manage the environment VPC, primary subnet, private service access range, and service networking connection behind the existing enable gate.
  Sub-agent: `openspec_implementer`
  Ownership: `modules/network/main.tf`, `modules/network/variables.tf`
  Expected output: Focused Terraform patch; list changed files in final response; do not revert edits outside this ownership.
  Blocking: Partial - environment wiring can proceed once output names are known.
- [x] 1.3 Update `modules/network` outputs so downstream modules receive stable VPC, subnet, and private service access identifiers, including null-safe values when disabled.
  Sub-agent: `openspec_implementer`
  Ownership: `modules/network/outputs.tf`
  Expected output: Output contract patch; list changed files in final response; do not revert edits outside this ownership.
  Blocking: Partial - root outputs and module consumers depend on this contract.

## 2. Environment Wiring

- [x] 2.1 Wire any new network module inputs through `environments/rc` and `environments/prod` while preserving explicit root selection and `module_activation.network`.
  Sub-agent: `openspec_implementer`
  Ownership: `environments/rc/**`, `environments/prod/**`
  Expected output: Environment-root wiring patch; list changed files in final response; do not revert edits outside this ownership.
  Blocking: Partial - validation depends on complete root wiring.
- [x] 2.2 Expose or preserve environment-level outputs needed by Cloud SQL, Cloud Run, and optional GKE follow-up tasks without leaking provider-internal resource references.
  Sub-agent: None
  Ownership: Local integration across environment outputs and downstream module inputs
  Blocking: Yes - requires cross-module judgment.

## 3. Documentation And Phase Evidence

- [x] 3.1 Update concise Terraform documentation if the network contract, outputs, or operator expectations change.
  Sub-agent: None
  Ownership: Local documentation updates in `docs/**` only if implementation changes user-facing behavior.
  Blocking: No.
- [x] 3.2 Update the P5-T03 task status/evidence in `../platform-blueprint-specs/implementation/phase-tasks/phase-5-terraform-infrastructure-tasks.md` after implementation validation is complete.
  Sub-agent: None
  Ownership: Local planning-repo evidence update after validation
  Blocking: Yes - only after checks pass.

## 4. Validation

- [x] 4.1 Run `make terraform-validate`.
  Sub-agent: None
  Ownership: Local validation
  Blocking: Yes.
- [x] 4.2 Run `make terraform-plan ENV=rc` and `make terraform-plan ENV=prod` when credentials and backend access are available; otherwise record the blocker and successful fallback checks.
  Sub-agent: None
  Ownership: Local validation and evidence capture
  Blocking: Yes.
- [x] 4.3 Run `openspec status --change p5-t03-implement-vpc-network-module` and confirm the change is apply-ready or complete for the current phase.
  Sub-agent: None
  Ownership: Local OpenSpec verification
  Blocking: Yes.
