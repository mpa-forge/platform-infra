output "service_name" {
  description = "Cloud Run service name."
  value       = try(google_cloud_run_v2_service.this[0].name, null)
}

output "service_uri" {
  description = "Cloud Run service URI."
  value       = try(google_cloud_run_v2_service.this[0].uri, null)
}

output "service_account_email" {
  description = "Runtime service account email."
  value       = try(google_service_account.runtime[0].email, null)
}

output "runtime_contract" {
  description = "Cloud Run API runtime contract consumed by routing, deploy, and runtime-switch tasks."
  value = {
    runtime_path                       = var.runtime_path
    ingress                            = var.ingress
    allow_unauthenticated              = var.allow_unauthenticated
    container_port                     = var.container_port
    cloudsql_enabled                   = var.cloudsql_enabled
    cloudsql_instance_connection_names = var.cloudsql_instance_connection_names
    cloudsql_mount_path                = var.cloudsql_mount_path
    plain_env_names                    = sort(keys(var.plain_env))
    secret_env_names                   = sort(keys(var.secret_env))
    runtime_secret_access_env_names    = sort(tolist(var.runtime_secret_access_env_names))
    runtime_secret_access_secret_ids   = sort(distinct([for contract in values(local.runtime_secret_access) : contract.secret]))
    startup_probe_path                 = var.startup_probe_path
    service_uri                        = try(google_cloud_run_v2_service.this[0].uri, null)
  }
}

output "runtime_secret_access_contract" {
  description = "Least-privilege runtime secret IAM contract for Cloud Run API secret delivery."
  value = {
    role                    = "roles/secretmanager.secretAccessor"
    required_secret_env     = sort(tolist(var.required_secret_env_names))
    configured_secret_env   = sort(keys(var.secret_env))
    iam_bound_secret_env    = sort(keys(local.runtime_secret_access))
    iam_bound_secret_ids    = sort(distinct([for contract in values(local.runtime_secret_access) : contract.secret]))
    service_account_email   = try(google_service_account.runtime[0].email, null)
    environment_secret_refs = { for env_name, contract in local.runtime_secret_access : env_name => contract.secret }
  }
}
