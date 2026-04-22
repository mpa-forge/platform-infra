output "project_boundaries" {
  description = "Project boundary contract for the RC environment."
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
    api_service_uri           = module.cloudrun_api.service_uri
    api_service_account_email = module.cloudrun_api.service_account_email
    api_runtime_contract      = module.cloudrun_api.runtime_contract
    grafana_token_secret_name = module.observability_support.grafana_token_secret_name
    cloudsql_connection_name  = module.cloudsql.instance_connection_name
    api_database_contract = {
      instance_name        = module.cloudsql.instance_name
      instance_connection  = module.cloudsql.instance_connection_name
      profile              = var.cloudsql_profile
      edition              = module.cloudsql.edition
      tier                 = module.cloudsql.tier
      database_name        = module.cloudsql.database_name
      database_user        = module.cloudsql.application_user_name
      host                 = local.cloudsql_socket_path
      password_secret_name = lookup(module.secrets.secret_ids, "api_db_password", local.db_password_secret_id)
    }
    artifact_registry_repos = module.gar.repository_ids
    artifact_registry_uris  = module.gar.repository_uris
    image_uri_prefixes      = module.gar.image_uri_prefixes
  }
}

output "network_contracts" {
  description = "Network identifiers exported for runtime and database modules."
  value = {
    network_name                         = module.network.network_name
    network_self_link                    = module.network.network_self_link
    subnetwork_name                      = module.network.subnetwork_name
    subnetwork_self_link                 = module.network.subnetwork_self_link
    private_service_access_range_name    = module.network.private_service_access_range_name
    private_service_access_connection_id = module.network.private_service_access_connection_id
  }
}
