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
