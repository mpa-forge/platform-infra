locals {
  network_tag = "${var.instance_name}-ingress"
  app_ports = sort(distinct([
    tostring(var.frontend_port),
    tostring(var.backend_port),
    "80",
    "443",
  ]))
}

resource "google_compute_address" "public" {
  count = var.enabled ? 1 : 0

  project = var.project_id
  region  = var.region
  name    = "${var.instance_name}-ip"
}

resource "google_service_account" "runtime" {
  count = var.enabled ? 1 : 0

  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Single VPS runtime (${var.instance_name})"
  description  = "Runtime identity for the ${var.instance_name} single-VPS preset."
}

resource "google_compute_firewall" "public" {
  count = var.enabled ? 1 : 0

  project       = var.project_id
  name          = "${var.instance_name}-public"
  network       = var.network_self_link
  direction     = "INGRESS"
  source_ranges = sort(tolist(var.public_source_ranges))
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = local.app_ports
  }
}

resource "google_compute_firewall" "ssh" {
  count = var.enabled && length(var.ssh_source_ranges) > 0 ? 1 : 0

  project       = var.project_id
  name          = "${var.instance_name}-ssh"
  network       = var.network_self_link
  direction     = "INGRESS"
  source_ranges = sort(tolist(var.ssh_source_ranges))
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "this" {
  count = var.enabled ? 1 : 0

  project      = var.project_id
  zone         = var.zone
  name         = var.instance_name
  machine_type = var.machine_type
  tags         = [local.network_tag]
  labels       = var.labels
  metadata     = var.metadata
  metadata_startup_script = var.startup_script

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link

    access_config {
      nat_ip = google_compute_address.public[0].address
    }
  }

  service_account {
    email  = google_service_account.runtime[0].email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    precondition {
      condition     = var.network_self_link != null && var.network_self_link != ""
      error_message = "network_self_link is required when the single-VPS stack is enabled."
    }

    precondition {
      condition     = var.subnetwork_self_link != null && var.subnetwork_self_link != ""
      error_message = "subnetwork_self_link is required when the single-VPS stack is enabled."
    }
  }
}
