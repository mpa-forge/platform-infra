locals {
  accessor_bindings = merge([
    for logical_name, secret in var.secrets : {
      for member in secret.accessors :
      "${logical_name}|${member}" => {
        logical_name = logical_name
        member       = member
      }
    }
  ]...)
}

resource "google_secret_manager_secret" "this" {
  for_each = var.enabled ? var.secrets : {}

  project   = var.project_id
  secret_id = each.value.secret_id
  labels    = var.labels

  replication {
    auto {}
  }

  annotations = each.value.annotations
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = var.enabled ? local.accessor_bindings : {}

  project   = var.project_id
  secret_id = google_secret_manager_secret.this[each.value.logical_name].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}
