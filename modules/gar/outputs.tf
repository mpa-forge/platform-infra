output "repository_ids" {
  description = "Artifact Registry repository ids keyed by logical name."
  value = {
    for repository_id, repository in google_artifact_registry_repository.this :
    repository_id => repository.repository_id
  }
}

output "repository_uris" {
  description = "Artifact Registry Docker repository URI prefixes keyed by repository id."
  value = {
    for repository_id, repository in google_artifact_registry_repository.this :
    repository_id => "${repository.location}-docker.pkg.dev/${repository.project}/${repository.repository_id}"
  }
}

output "image_uri_prefixes" {
  description = "Expected immutable image URI prefixes keyed by repository id and image name."
  value = merge(concat(
    [{}],
    [
      for repository_id, repository in var.repositories : {
        for image_name in repository.image_names :
        "${repository_id}/${image_name}" => "${var.region}-docker.pkg.dev/${var.project_id}/${repository_id}/${image_name}:sha-"
      }
    ]
  )...)
}
