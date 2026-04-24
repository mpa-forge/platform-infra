output "secret_ids" {
  description = "Versionless secret ids keyed by logical name."
  value = {
    for logical_name, secret in local.secret_catalog :
    logical_name => secret.secret_id
  }
}

output "secret_names" {
  description = "Secret resource names keyed by logical name."
  value = {
    for logical_name, secret in local.secret_catalog :
    logical_name => secret.secret_name
  }
}

output "secret_catalog" {
  description = "Stable runtime secret catalog keyed by logical name, including Cloud Run and ESO mapping metadata."
  value       = local.secret_catalog
}

output "cloud_run_secret_catalog" {
  description = "Versionless Cloud Run secret references keyed by env var name."
  value       = local.cloud_run_secret_catalog
}

output "eso_secret_catalog" {
  description = "ESO-facing secret mapping metadata keyed by logical name."
  value       = local.eso_secret_catalog
}
