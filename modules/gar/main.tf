locals {
  ci_bindings = merge([
    for repository_id, repository in var.repositories : {
      for member in repository.ci_push_members :
      "${repository_id}|${member}|writer" => {
        repository_id = repository_id
        member        = member
        role          = "roles/artifactregistry.writer"
      }
    }
  ]...)

  runtime_bindings = merge([
    for repository_id, repository in var.repositories : {
      for member in repository.runtime_pull_members :
      "${repository_id}|${member}|reader" => {
        repository_id = repository_id
        member        = member
        role          = "roles/artifactregistry.reader"
      }
    }
  ]...)
}

resource "google_artifact_registry_repository" "this" {
  for_each = var.enabled ? var.repositories : {}

  project       = var.project_id
  location      = var.region
  repository_id = each.key
  description   = each.value.description
  format        = each.value.format
  labels        = var.labels
}

resource "google_artifact_registry_repository_iam_member" "ci_push" {
  for_each = var.enabled ? local.ci_bindings : {}

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.this[each.value.repository_id].repository_id
  role       = each.value.role
  member     = each.value.member
}

resource "google_artifact_registry_repository_iam_member" "runtime_pull" {
  for_each = var.enabled ? local.runtime_bindings : {}

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.this[each.value.repository_id].repository_id
  role       = each.value.role
  member     = each.value.member
}
