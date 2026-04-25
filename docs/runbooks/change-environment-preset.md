# Change Environment Preset Runbook

This runbook explains how to switch an environment root to a different
`deployment_preset` in `platform-infra`.

## When To Use This

Use this runbook when you want to change the runtime topology of an existing
environment without creating a new Terraform root.

Examples:

- switch `rc` from `single-vps` to `cloudrun-cloudsql`
- switch `prod` from `cloudrun-cloudsql` to `gke-cloudsql`
- test a lower-cost or simpler topology before moving back to a managed path

## Current Presets

- `single-vps`
  - frontend, backend, and PostgreSQL on one VM
- `cloudrun-cloudsql`
  - backend on Cloud Run
  - database on Cloud SQL
  - frontend remains external/manual in the current Terraform implementation
- `cloudrun-cdn-cloudsql`
  - backend on Cloud Run
  - database on Cloud SQL
  - frontend modeled as CDN/static-hosting contract output
- `gke-cloudsql`
  - backend on GKE
  - database on Cloud SQL
  - frontend modeled as CDN/static-hosting contract output

## Files You Will Change

- RC: [environments/rc/terraform.tfvars](/C:/Users/Miquel/dev/platform-infra/environments/rc/terraform.tfvars)
- Prod: [environments/prod/terraform.tfvars](/C:/Users/Miquel/dev/platform-infra/environments/prod/terraform.tfvars)

Relevant root inputs:

- `deployment_preset`
- `deployment_enabled`

## Procedure

### 1. Pick the target environment

Choose one root:

- `rc`
- `prod`

Do not treat presets as new environments. The root stays the same; only the
topology changes.

### 2. Pick the target preset

Decide which preset should become active for that root.

Before changing it, check whether the new preset changes:

- runtime type for the backend
- database location
- frontend delivery model
- secret and IAM expectations
- cost and recovery characteristics

### 3. Update the root tfvars file

Edit the environment `terraform.tfvars` file and set the desired preset.

Example for RC:

```hcl
deployment_preset = "cloudrun-cloudsql"
```

Example for prod:

```hcl
deployment_preset = "gke-cloudsql"
```

If you want Terraform to create resources for the selected topology, also set:

```hcl
deployment_enabled = true
```

If you only want to record the intended topology without creating resources
yet, leave `deployment_enabled = false` or omit it and use the default.

### 4. Validate the configuration

Run:

```powershell
make terraform-validate
```

This verifies that the selected preset and all module contracts remain valid.

### 5. Review the environment plan

Run a plan for the changed environment:

```powershell
make terraform-plan ENV=rc
```

or

```powershell
make terraform-plan ENV=prod
```

Review the plan for:

- resources that will be created
- resources that will be destroyed
- secret, IAM, and network changes
- runtime path changes reflected in outputs

### 6. Confirm the output contract

After the plan, confirm that the environment still exposes the expected
normalized outputs:

- `deployment_contract.active_preset`
- `deployment_contract.frontend_contract`
- `deployment_contract.backend_contract`
- `deployment_contract.database_contract`
- `deployment_contract.operational_contract`

The keys should stay stable even though the values change with the preset.

### 7. Apply only after topology review

When the plan is correct and the topology change is intentional, apply using
the normal environment workflow:

```powershell
make terraform-apply ENV=rc
```

or

```powershell
make terraform-apply ENV=prod
```

## Preset Change Guidance

### Switching to `single-vps`

Expect:

- one VM path for frontend, backend, and PostgreSQL
- different operational and recovery tradeoffs than Cloud Run or Cloud SQL
- no managed Cloud SQL contract for the selected environment while this preset
  is active

Use this when:

- the project is small
- fixed cloud costs need to stay low
- simpler end-to-end hosting matters more than managed-service resilience

### Switching to `cloudrun-cloudsql`

Expect:

- managed Cloud Run backend
- managed Cloud SQL database
- normalized backend/database outputs aligned to the managed path

Use this when:

- you want the current managed baseline
- scale-to-zero backend behavior is useful
- Cloud SQL operational guarantees matter

### Switching to `cloudrun-cdn-cloudsql`

Expect:

- Cloud Run backend
- Cloud SQL database
- frontend represented as CDN/static-hosting contract in outputs

Use this when:

- frontend delivery should be modeled as static/CDN-backed
- backend should remain on Cloud Run

### Switching to `gke-cloudsql`

Expect:

- GKE backend path
- Cloud SQL database
- GKE workload identity and ESO-related secret wiring

Use this when:

- you intentionally need the GKE runtime path
- the extra operational complexity is justified

## Risk Checks Before Apply

Before applying a preset change, explicitly review:

- whether the plan destroys runtime resources from the previous preset
- whether data migration or backup steps are needed
- whether DNS, frontend routing, or deployment workflow expectations change
- whether the target environment should really stay enabled during the switch

## Rollback

To roll back a preset change:

1. restore the previous `deployment_preset`
2. run `make terraform-validate`
3. run `make terraform-plan ENV=<env>`
4. confirm the reverse topology change is correct
5. apply using the normal environment workflow

## Related Docs

- [docs/deployment-presets.md](/C:/Users/Miquel/dev/platform-infra/docs/deployment-presets.md)
- [README.md](/C:/Users/Miquel/dev/platform-infra/README.md)
- [docs/terraform-file-guide.md](/C:/Users/Miquel/dev/platform-infra/docs/terraform-file-guide.md)
