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

  dynamic "cleanup_policies" {
    for_each = each.value.cleanup_policies
    content {
      id     = cleanup_policies.key
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition == null ? [] : [cleanup_policies.value.condition]
        content {
          tag_state             = condition.value.tag_state
          tag_prefixes          = condition.value.tag_prefixes
          version_name_prefixes = condition.value.version_name_prefixes
          package_name_prefixes = condition.value.package_name_prefixes
          older_than            = condition.value.older_than
          newer_than            = condition.value.newer_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions == null ? [] : [cleanup_policies.value.most_recent_versions]
        content {
          keep_count            = most_recent_versions.value.keep_count
          package_name_prefixes = most_recent_versions.value.package_name_prefixes
        }
      }
    }
  }
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
