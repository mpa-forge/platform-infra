resource "google_compute_network" "this" {
  count = var.enabled ? 1 : 0

  project                         = var.project_id
  name                            = var.network_name
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  mtu                             = 1460
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "primary" {
  count = var.enabled ? 1 : 0

  project                  = var.project_id
  name                     = var.subnet_name
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr
  network                  = google_compute_network.this[0].id
  private_ip_google_access = true
  description              = "Primary subnet for ${var.network_name}."
}

resource "google_compute_global_address" "private_service_access" {
  count = var.enabled ? 1 : 0

  project       = var.project_id
  name          = "${var.network_name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.this[0].id
}

resource "google_service_networking_connection" "private_service_access" {
  count = var.enabled ? 1 : 0

  network                 = google_compute_network.this[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access[0].name]
}
