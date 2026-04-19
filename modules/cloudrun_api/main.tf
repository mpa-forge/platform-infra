resource "google_service_account" "runtime" {
  count = var.enabled ? 1 : 0

  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Cloud Run API runtime (${var.service_name})"
}

resource "google_project_iam_member" "cloudsql_client" {
  count = var.enabled && length(var.cloudsql_instance_connection_names) > 0 ? 1 : 0

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime[0].email}"
}

resource "google_secret_manager_secret_iam_member" "runtime_secret_access" {
  for_each = var.enabled ? var.secret_env : {}

  project   = var.project_id
  secret_id = each.value.secret
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime[0].email}"
}

resource "google_cloud_run_v2_service" "this" {
  count = var.enabled ? 1 : 0

  project             = var.project_id
  name                = var.service_name
  location            = var.region
  ingress             = var.ingress
  labels              = var.labels
  deletion_protection = false

  template {
    service_account                  = google_service_account.runtime[0].email
    timeout                          = var.timeout
    max_instance_request_concurrency = var.max_instance_request_concurrency
    labels                           = var.labels

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    dynamic "volumes" {
      for_each = length(var.cloudsql_instance_connection_names) > 0 ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = var.cloudsql_instance_connection_names
        }
      }
    }

    containers {
      image = var.container_image

      resources {
        limits = var.container_limits
      }

      dynamic "env" {
        for_each = var.plain_env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }
    }
  }
}
