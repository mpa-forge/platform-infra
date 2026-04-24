output "project_boundaries" {
  description = "Project boundary contract for the environment root."
  value = {
    environment       = var.environment
    service_project   = var.project_id
    state_project     = var.state_project_id
    runtime_baseline  = "cloud_run"
    active_preset     = var.deployment_preset
    deployment_enabled = var.deployment_enabled
    gke_enabled       = local.module_activation.gke
  }
}

output "deployment_contract" {
  description = "Preset-normalized deployment contract for this environment."
  value       = local.deployment_contract
}

output "service_contracts" {
  description = "Baseline service, runtime, and secret contracts exported by the shared stack."
  value       = local.service_contracts
}

output "network_contracts" {
  description = "Network identifiers exported for runtime modules."
  value = {
    network_name                         = module.network.network_name
    network_self_link                    = module.network.network_self_link
    subnetwork_name                      = module.network.subnetwork_name
    subnetwork_self_link                 = module.network.subnetwork_self_link
    private_service_access_range_name    = module.network.private_service_access_range_name
    private_service_access_connection_id = module.network.private_service_access_connection_id
  }
}
