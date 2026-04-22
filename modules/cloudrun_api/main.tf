locals {
  service_annotations = merge(
    {
      "run.googleapis.com/launch-stage" = var.launch_stage
    },
    var.annotations
  )

  has_cloudsql = var.cloudsql_enabled
}

resource "google_service_account" "runtime" {
  count = var.enabled ? 1 : 0

  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Cloud Run API runtime (${var.service_name})"
  description  = "Runtime identity for the ${var.service_name} Cloud Run API service."
}

resource "google_project_iam_member" "cloudsql_client" {
  count = var.enabled && local.has_cloudsql ? 1 : 0

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

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.enabled && var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service" "this" {
  count = var.enabled ? 1 : 0

  project             = var.project_id
  name                = var.service_name
  location            = var.region
  ingress             = var.ingress
  labels              = var.labels
  annotations         = local.service_annotations
  deletion_protection = false

  template {
    service_account                  = google_service_account.runtime[0].email
    timeout                          = var.timeout
    max_instance_request_concurrency = var.max_instance_request_concurrency
    labels                           = var.labels
    annotations                      = var.template_annotations

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    dynamic "volumes" {
      for_each = local.has_cloudsql ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = var.cloudsql_instance_connection_names
        }
      }
    }

    containers {
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = var.container_limits
      }

      dynamic "volume_mounts" {
        for_each = local.has_cloudsql ? [1] : []
        content {
          name       = "cloudsql"
          mount_path = var.cloudsql_mount_path
        }
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

      startup_probe {
        initial_delay_seconds = var.startup_probe_initial_delay_seconds
        period_seconds        = var.startup_probe_period_seconds
        timeout_seconds       = var.startup_probe_timeout_seconds
        failure_threshold     = var.startup_probe_failure_threshold

        http_get {
          path = var.startup_probe_path
          port = var.container_port
        }
      }
    }
  }
}
