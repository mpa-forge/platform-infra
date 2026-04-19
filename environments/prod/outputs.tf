output "project_boundaries" {
  description = "Project boundary contract for the prod environment."
  value = {
    environment      = var.environment
    service_project  = var.project_id
    state_project    = var.state_project_id
    runtime_baseline = "cloud_run"
    gke_enabled      = var.module_activation.gke
  }
}

output "service_contracts" {
  description = "Baseline service and secret contracts exported by the root."
  value = {
    api_service_name          = module.cloudrun_api.service_name
    api_service_account_email = module.cloudrun_api.service_account_email
    grafana_token_secret_name = module.observability_support.grafana_token_secret_name
    cloudsql_connection_name  = module.cloudsql.instance_connection_name
    artifact_registry_repos   = module.gar.repository_ids
  }
}
