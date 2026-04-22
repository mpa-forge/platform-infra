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
    cloudsql_instance_connection_names = var.cloudsql_instance_connection_names
    cloudsql_mount_path                = var.cloudsql_mount_path
    startup_probe_path                 = var.startup_probe_path
    service_uri                        = try(google_cloud_run_v2_service.this[0].uri, null)
  }
}
