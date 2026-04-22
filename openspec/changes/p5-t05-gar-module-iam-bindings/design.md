## Context

`platform-infra` already has a skeletal `modules/gar` module and `rc`/`prod`
roots that declare the intended repository set. Phase 4 image publishing, Phase
6 Cloud Run deployment, and Phase 8 retention/cost controls all depend on a
stable Artifact Registry contract. The platform standards require regional
`us-east4` artifact flows, immutable `sha-<git_sha_12>` deployment tags,
least-privilege CI/runtime identities, and strict `rc`/`prod` separation.

## Goals / Non-Goals

**Goals:**

- Create only the currently needed regional GAR repositories: `apps`,
  `workers`, and `tools`.
- Keep each environment's repositories in that environment project and region.
- Add cleanup policy to remove untagged artifacts and prune old `sha-` images
  while retaining enough recent images for rollback.
- Separate CI writer permissions from runtime reader permissions at repository
  scope.
- Export image URI prefixes so downstream workflows do not hard-code registry
  locations.

**Non-Goals:**

- Implement GitHub WIF provider creation or CI workflow changes; those remain
  Phase 4/P5-T10A work.
- Publish real images or copy artifacts between `rc` and `prod`.
- Add broad project-level Artifact Registry permissions.

## Decisions

### Decision: Use one regional GAR module for `apps`, `workers`, and `tools`

The module keeps the repository set small and maps directly to the naming
standard: applications, worker images, and tool/build images. This avoids
over-provisioning while leaving enough separation for future cleanup and IAM
policy differences.

Alternative considered: create one GAR repository per service. Rejected for the
baseline because it creates more resources and IAM surfaces before we need that
granularity.

### Decision: Cleanup policy is part of the Terraform repository contract

Every repository gets a common policy that deletes untagged artifacts after a
short grace period and deletes older `sha-` tagged artifacts after the retention
window. A most-recent policy keeps a configurable number of recent `sha-`
versions to protect rollback and debugging.

Alternative considered: handle cleanup manually or in a later script only.
Rejected because image storage cost grows quietly and should be controlled from
the first repository apply.

### Decision: CI push and runtime pull stay repository-scoped

The module accepts `ci_push_members` and `runtime_pull_members` per repository.
CI receives `roles/artifactregistry.writer`; runtime identities receive
`roles/artifactregistry.reader`. The roots wire the Cloud Run API service
account as an `apps` reader, while CI principals remain empty until WIF
principal strings are finalized.

Alternative considered: project-wide Artifact Registry roles. Rejected because
the access model requires least-privilege automation and runtime identities.

### Decision: No automatic `rc` to `prod` image duplication

`rc` and `prod` repositories remain separate by project and root path, but this
change does not copy every image into both projects. Promotion workflows can
copy only release-approved images later when production deploy policy requires
it.

Alternative considered: duplicate every pushed image to prod. Rejected because
it increases storage cost and weakens promotion semantics before release
automation exists.

## Risks / Trade-offs

- [Cleanup removes useful debugging images] -> Retention windows and
  most-recent counts are configurable per root.
- [CI principal strings are not final yet] -> Keep the module ready for
  repository-scoped writer bindings and populate root variables when WIF is
  implemented.
- [Runtime reader binding may reference disabled runtime service accounts] ->
  Use deterministic service-account member strings so GAR can be planned before
  Cloud Run is enabled.
- [Provider cleanup policy schema drift] -> Validate against the pinned
  `hashicorp/google` provider version before committing.

## Migration Plan

1. Add GAR cleanup policy and URI outputs to `modules/gar`.
2. Add environment-root variables for GAR repository retention and principal
   lists.
3. Wire `apps`, `workers`, and `tools` repositories in both roots with regional
   defaults and runtime pull identity for the API service account.
4. Validate all Terraform modules/roots and run GAR-enabled plans for `rc` and
   `prod`.
