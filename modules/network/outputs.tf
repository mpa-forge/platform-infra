output "network_name" {
  description = "Provisioned VPC name."
  value       = try(google_compute_network.this[0].name, null)
}

output "network_self_link" {
  description = "Self link for the VPC network."
  value       = try(google_compute_network.this[0].self_link, null)
}

output "subnetwork_name" {
  description = "Primary subnet name."
  value       = try(google_compute_subnetwork.primary[0].name, null)
}

output "subnetwork_self_link" {
  description = "Self link for the primary subnet."
  value       = try(google_compute_subnetwork.primary[0].self_link, null)
}

output "private_service_access_range_name" {
  description = "Reserved peering range for Google-managed services."
  value       = try(google_compute_global_address.private_service_access[0].name, null)
}
