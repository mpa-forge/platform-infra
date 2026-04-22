## Context

`platform-infra` already has one Terraform root per environment and a skeletal
`cloudrun_api` module. `backend-api` specs require explicit Cloud Run baseline
selection, direct OTLP telemetry, required startup environment variables, and a
later reversible GKE path. `P5-T03` established network outputs that downstream
runtime modules can consume without reaching into network internals.

## Goals / Non-Goals

**Goals:**

- Make the Cloud Run API module a complete baseline runtime contract for
  `rc` and `prod`.
- Keep Cloud Run enabled through explicit root variables and module activation,
  not implicit workspace state.
- Wire required backend startup variables, direct OTLP observability settings,
  secret-backed token delivery, Cloud SQL sockets, service-account IAM, scaling,
  concurrency, and ingress controls.
- Export stable service and identity values for later routing, deployment, and
  runtime-switch work.

**Non-Goals:**

- Provision Cloud SQL, GAR, GSM payload values, or `/api/*` edge routing beyond
  the Cloud Run service attachment points.
- Deploy a real backend image or prove live Cloud Run revision health in this
  change; that remains gated by later deployment and apply tasks.
- Create the optional GKE runtime path.

## Decisions

### Decision: Cloud Run v2 service remains the module primitive

Cloud Run v2 exposes the revision template fields needed for service account,
scaling, concurrency, startup probe, Cloud SQL volumes, secret env references,
labels, and launch-stage annotations in one resource.

Alternative considered: split IAM and service definition across several helper
modules. Rejected for `P5-T04` because a single focused module keeps the
baseline runtime easy to validate before Phase 5 adds routing and CI apply
automation.

### Decision: Environment roots pass backend startup contract explicitly

The roots build an API env map that includes `APP_ENV`, `LOG_LEVEL`,
`HTTP_PORT`, `AUTH_ISSUER_URL`, `AUTH_AUDIENCE`, `DATABASE_URL`,
`API_RUNTIME_PATH`, and the observability values produced by
`observability_support`.

Alternative considered: leave these values to deployment-time overrides.
Rejected because Terraform plans would not describe the actual baseline runtime
contract, and later tasks would have to rediscover required env wiring.

### Decision: Cloud SQL is attached by connection name and Unix socket path

The module accepts Cloud SQL connection names and exposes the standard
`/cloudsql/<connection-name>` socket mount path through root-computed
`DATABASE_URL`. This matches Cloud Run's managed Cloud SQL integration and keeps
network/private-service-access details behind the Cloud SQL and network modules.

Alternative considered: inject a TCP private IP connection string now. Rejected
because the backend runtime can consume the Cloud Run SQL socket path while
later Cloud SQL and runtime-switch work refine exact database credentials and
user provisioning.

### Decision: Invocation policy is controlled by input

The module creates an optional `roles/run.invoker` binding for
`allUsers` only when explicitly requested. The default remains private/internal
load-balancer ingress so later edge-routing work can attach the service without
accidentally publishing it directly.

Alternative considered: make unauthenticated public invocation the default.
Rejected because the platform expects `/api/*` routing to be owned by a later
edge task rather than ad hoc public service URLs.

## Risks / Trade-offs

- [Secrets exist without payload values] -> The module grants access to secret
  names and versions, but operators or CI must populate payloads before live
  startup validation can pass.
- [Placeholder image cannot run] -> `terraform plan` validates resource shape,
  while deployment health waits for Phase 6 image publishing and apply tasks.
- [Database credentials are not final] -> This change wires the socket path and
  required env key; `P5-T06` owns database users, passwords, and migration
  details.
- [Planning repo task docs are already dirty] -> Keep implementation evidence in
  `platform-infra` for this change and avoid overwriting unrelated planning
  edits.

## Migration Plan

1. Update the module contract and environment-root wiring.
2. Validate `modules/cloudrun_api`, `environments/rc`, and `environments/prod`
   through repo-local Terraform validation.
3. Run environment plans with default-disabled modules to prove no accidental
   resource creation.
4. Optionally enable network, secrets, Cloud SQL, and Cloud Run in `rc` during
   later apply work once real image and secret payloads exist.

Rollback is a normal Terraform code rollback before apply; after apply, disable
`module_activation.cloudrun_api` in the affected root and apply the reviewed
plan.

## Open Questions

- The final production auth issuer and audience values remain environment
  inputs until the provider setup is complete.
