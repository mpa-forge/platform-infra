resource "google_sql_database_instance" "this" {
  count = var.enabled ? 1 : 0

  project             = var.project_id
  name                = var.instance_name
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    user_labels       = var.labels

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
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
  }
}

resource "google_sql_database" "app" {
  count = var.enabled ? 1 : 0

  project  = var.project_id
  name     = var.database_name
  instance = google_sql_database_instance.this[0].name
}
