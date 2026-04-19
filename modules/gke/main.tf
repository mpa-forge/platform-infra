resource "google_container_cluster" "this" {
  count = var.enabled ? 1 : 0

  project             = var.project_id
  name                = var.cluster_name
  location            = var.region
  enable_autopilot    = true
  network             = var.network_self_link
  subnetwork          = var.subnetwork_self_link
  deletion_protection = var.deletion_protection
  resource_labels     = var.labels

  release_channel {
    channel = var.release_channel
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {}
}
