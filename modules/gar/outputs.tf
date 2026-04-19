output "repository_ids" {
  description = "Artifact Registry repository ids keyed by logical name."
  value = {
    for repository_id, repository in google_artifact_registry_repository.this :
    repository_id => repository.repository_id
  }
}
