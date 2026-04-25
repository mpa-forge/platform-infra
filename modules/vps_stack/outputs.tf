locals {
  frontend_suffix = var.frontend_port == 80 ? "" : ":${var.frontend_port}"
  backend_suffix  = var.backend_port == 80 ? "" : ":${var.backend_port}"
}

output "instance_name" {
  description = "Single-VPS instance name."
  value       = try(google_compute_instance.this[0].name, null)
}

output "public_ip" {
  description = "Public IPv4 address assigned to the single VPS."
  value       = try(google_compute_address.public[0].address, null)
}

output "internal_ip" {
  description = "Internal IPv4 address assigned to the single VPS."
  value       = try(google_compute_instance.this[0].network_interface[0].network_ip, null)
}

output "service_account_email" {
  description = "Service account email attached to the single VPS."
  value       = try(google_service_account.runtime[0].email, null)
}

output "frontend_url" {
  description = "Derived frontend URL for the single-VPS preset."
  value       = try("http://${google_compute_address.public[0].address}${local.frontend_suffix}", null)
}

output "backend_url" {
  description = "Derived backend URL for the single-VPS preset."
  value       = try("http://${google_compute_address.public[0].address}${local.backend_suffix}", null)
}

output "database_host" {
  description = "Database host contract for services running on the single VPS."
  value       = var.enabled ? "127.0.0.1" : null
}

output "database_port" {
  description = "Database port contract for services running on the single VPS."
  value       = var.enabled ? var.database_port : null
}

output "runtime_contract" {
  description = "Runtime contract exported by the single-VPS stack."
  value = {
    runtime_path              = "vps"
    zone                      = var.zone
    machine_type              = var.machine_type
    public_ip                 = try(google_compute_address.public[0].address, null)
    frontend_url              = try("http://${google_compute_address.public[0].address}${local.frontend_suffix}", null)
    backend_url               = try("http://${google_compute_address.public[0].address}${local.backend_suffix}", null)
    database_host             = var.enabled ? "127.0.0.1" : null
    database_port             = var.enabled ? var.database_port : null
    startup_script_configured = var.startup_script != null && trimspace(var.startup_script) != ""
  }
}
