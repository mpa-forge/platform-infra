# Artifact Registry Baseline

`P5-T05` owns the Google Artifact Registry baseline for platform images.

## Repository Set

Each environment root creates only the current baseline repositories when
`module_activation.gar = true`:

- `apps`: application images such as `backend-api`
- `workers`: background and automation worker images
- `tools`: shared tooling or utility images

Repositories are regional and use the environment region, currently `us-east4`,
so Cloud Run pulls do not cross regions by default.

## Image Tag Contract

Deployment images must use immutable SHA tags:

```text
${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:sha-<git_sha_12>
```

Examples:

```text
us-east4-docker.pkg.dev/mpa-forge-bp-rc/apps/backend-api:sha-abc123def456
us-east4-docker.pkg.dev/mpa-forge-bp-prod/workers/platform-ai-workers:sha-abc123def456
```

Do not deploy mutable `latest` tags.

## IAM Split

GAR permissions are repository-scoped:

- CI push principals receive `roles/artifactregistry.writer`
- runtime principals receive `roles/artifactregistry.reader`

The Cloud Run API runtime service account is wired as a reader on the `apps`
repository. CI writer principals remain environment inputs so the later
GitHub WIF work can provide exact principal strings without changing the GAR
module.

## Cleanup Policy

Each repository includes cleanup policies:

- delete untagged artifacts after the configured untagged retention window
- delete older `sha-` tagged artifacts after the configured tagged retention
  window
- keep a configurable number of recent image versions for rollback/debugging

Defaults:

- `rc`: keep recent 20 SHA versions, prune old SHA versions after 30 days
- `prod`: keep recent 30 SHA versions, prune old SHA versions after 90 days
- both: prune untagged artifacts after 7 days

## Environment Separation

`rc` and `prod` repositories live in separate GCP projects and roots. Images
are not automatically duplicated across environments; promotion workflows should
copy only reviewed release images when production policy requires that.
