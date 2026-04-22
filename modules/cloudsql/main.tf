resource "google_sql_database_instance" "this" {
  count = var.enabled ? 1 : 0

  project             = var.project_id
  name                = var.instance_name
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size_gb
    disk_autoresize   = var.disk_autoresize
    edition           = var.edition
    user_labels       = var.labels

    backup_configuration {
      enabled                        = var.backup_enabled
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      start_time                     = var.backup_start_time
      transaction_log_retention_days = var.transaction_log_retention_days
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.private_network_self_link
      enable_private_path_for_google_cloud_services = true
    }

    maintenance_window {
      day          = var.maintenance_window.day
      hour         = var.maintenance_window.hour
      update_track = var.maintenance_window.update_track
    }

    dynamic "database_flags" {
      for_each = var.database_flags

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.private_network_self_link != null && var.private_network_self_link != ""
      error_message = "private_network_self_link is required when the Cloud SQL module is enabled."
    }
  }
}

resource "google_sql_database" "app" {
  count = var.enabled ? 1 : 0

  project  = var.project_id
  name     = var.database_name
  instance = google_sql_database_instance.this[0].name
}

resource "google_sql_user" "app" {
  count = var.enabled ? 1 : 0

  project  = var.project_id
  name     = var.application_user_name
  instance = google_sql_database_instance.this[0].name
  password = var.application_user_password
  type     = "BUILT_IN"

  lifecycle {
    precondition {
      condition     = nonsensitive(var.application_user_password) != null && nonsensitive(var.application_user_password) != ""
      error_message = "application_user_password is required to manage the Cloud SQL application user."
    }
  }
}
