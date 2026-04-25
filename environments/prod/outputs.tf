output "project_boundaries" {
  description = "Project boundary contract for the prod environment."
  value       = module.stack.project_boundaries
}

output "deployment_contract" {
  description = "Preset-normalized deployment contract for the prod environment."
  value       = module.stack.deployment_contract
}

output "service_contracts" {
  description = "Baseline service and secret contracts exported by the root."
  value       = module.stack.service_contracts
}

output "grafana_dashboard_provisioning" {
  description = "Grafana dashboard folder and dashboard resources managed from source-controlled definitions."
  value = {
    stack_url     = var.grafana_stack_url
    manifest_path = local.grafana_dashboard_manifest_path
    source_root   = local.grafana_dashboard_source_root
    folder        = module.grafana_dashboards.folder
    dashboards    = module.grafana_dashboards.dashboards
  }
}

output "network_contracts" {
  description = "Network identifiers exported for runtime and database modules."
  value       = module.stack.network_contracts
}
