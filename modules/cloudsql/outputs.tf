output "instance_name" {
  description = "Cloud SQL instance name."
  value       = try(google_sql_database_instance.this[0].name, null)
}

output "instance_id" {
  description = "Cloud SQL instance resource id."
  value       = try(google_sql_database_instance.this[0].id, null)
}

output "instance_self_link" {
  description = "Cloud SQL instance self link."
  value       = try(google_sql_database_instance.this[0].self_link, null)
}

output "instance_connection_name" {
  description = "Cloud SQL connection name for Cloud Run or other clients."
  value       = try(google_sql_database_instance.this[0].connection_name, null)
}

output "instance_private_ip_address" {
  description = "Private IP address assigned to the Cloud SQL instance."
  value       = try(google_sql_database_instance.this[0].private_ip_address, null)
}

output "edition" {
  description = "Cloud SQL edition configured for the instance."
  value       = var.enabled ? var.edition : null
}

output "tier" {
  description = "Cloud SQL machine tier configured for the instance."
  value       = var.enabled ? var.tier : null
}

output "instance_socket_path" {
  description = "Cloud SQL Unix socket path for runtime DB_HOST values."
  value       = try("/cloudsql/${google_sql_database_instance.this[0].connection_name}", null)
}

output "database_name" {
  description = "Application database name."
  value       = try(google_sql_database.app[0].name, null)
}

output "application_user_name" {
  description = "Application database user name."
  value       = try(google_sql_user.app[0].name, null)
}

output "application_user_password_secret_id" {
  description = "Secret Manager secret id expected to store the application database user password."
  value       = var.enabled ? var.application_user_password_secret_id : null
}

output "deletion_protection" {
  description = "Whether Cloud SQL deletion protection is enabled."
  value       = var.enabled ? var.deletion_protection : null
}

output "labels" {
  description = "Labels applied to the Cloud SQL instance."
  value       = var.enabled ? var.labels : {}
}
