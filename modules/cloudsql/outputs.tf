output "instance_name" {
  description = "Cloud SQL instance name."
  value       = try(google_sql_database_instance.this[0].name, null)
}

output "instance_connection_name" {
  description = "Cloud SQL connection name for Cloud Run or other clients."
  value       = try(google_sql_database_instance.this[0].connection_name, null)
}

output "database_name" {
  description = "Application database name."
  value       = try(google_sql_database.app[0].name, null)
}
