# Runtime Secret Catalog

`modules/secrets` now exposes a reusable, versionless runtime secret catalog for
environment roots. The module still manages only Secret Manager metadata and
IAM. Secret payloads and secret versions stay out of Terraform.

## Contract Goals

- keep Google Secret Manager as the canonical secret source
- keep secret references versionless inside the shared catalog
- let Cloud Run roots choose a version such as `"latest"` at the point of use
- expose stable identifiers and mapping metadata for later GKE and ESO work

## Module Input Shape

Environment roots can keep using the existing `secrets` map and optionally add
catalog metadata per logical secret:

```hcl
module "secrets" {
  source = "../../modules/secrets"

  enabled      = var.module_activation.secrets
  project_id   = var.project_id
  environment  = var.environment
  catalog_name = "runtime"
  labels       = local.labels

  secrets = {
    api_db_password = {
      secret_id              = "api-db-password-${var.environment}"
      cloud_run_env_var      = "DB_PASSWORD"
      eso_target_secret_name = "api-runtime"
      eso_target_secret_key  = "DB_PASSWORD"
      accessors = [
        "serviceAccount:api-runtime@${var.project_id}.iam.gserviceaccount.com",
      ]
      annotations = {
        owner = "platform-infra"
      }
    }
  }
}
```

When `environment` is set, every `secret_id` must end with `-<environment>`.
This keeps the catalog explicitly environment-scoped.

## Stable Outputs

The module now exports:

- `secret_ids`: logical name -> versionless Secret Manager secret id
- `secret_names`: logical name -> `projects/<project>/secrets/<secret_id>`
- `secret_catalog`: full per-secret metadata, including accessors and delivery hints
- `cloud_run_secret_catalog`: env var -> versionless Cloud Run secret reference
- `eso_secret_catalog`: logical name -> remote ref and target-secret mapping data

These outputs are derived from the declared catalog, so they remain stable even
when the module is disabled in a root.

## Cloud Run Usage

The shared catalog intentionally does not set a secret version. A Cloud Run root
can add the runtime version when wiring `secret_env`:

```hcl
secret_env = {
  for env_name, secret_ref in module.secrets.cloud_run_secret_catalog :
  env_name => {
    secret  = secret_ref.secret_id
    version = "latest"
  }
}
```

This keeps the cross-root contract versionless while still matching the Cloud
Run API requirement that a revision references a concrete version selector.

## GKE and ESO Usage

`eso_secret_catalog` exposes the metadata Phase 6 needs without redefining the
catalog:

- `remote_ref_key`: canonical GSM secret id
- `target_secret_name`: intended Kubernetes secret name
- `target_secret_key`: intended key inside that Kubernetes secret

If no explicit ESO target fields are provided, the module defaults to:

- `target_secret_name = secret_id`
- `target_secret_key = cloud_run_env_var` when present, otherwise the logical name

## Payload Handling

Terraform should create only the Secret Manager secret objects and IAM
bindings. Operators must add secret versions out of band, for example with
`gcloud secrets versions add`, after the placeholder resources exist.
