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

output "network_contracts" {
  description = "Network identifiers exported for runtime and database modules."
  value       = module.stack.network_contracts
}
