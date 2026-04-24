locals {
  workload_pool = "${var.project_id}.svc.id.goog"

  workload_identity_principals = {
    for principal_key, principal in var.workload_identity_principals :
    principal_key => {
      google_service_account_id  = principal.google_service_account_id
      kubernetes_namespace       = principal.kubernetes_namespace
      kubernetes_service_account = principal.kubernetes_service_account
      secret_ids                 = principal.secret_ids
      display_name               = principal.display_name
      description                = principal.description
      wi_member = format(
        "serviceAccount:%s[%s/%s]",
        local.workload_pool,
        principal.kubernetes_namespace,
        principal.kubernetes_service_account
      )
    }
  }

  workload_identity_secret_access = {
    for binding in flatten([
      for principal_key, principal in local.workload_identity_principals : [
        for secret_id in principal.secret_ids : {
          key           = "${principal_key}|${secret_id}"
          principal_key = principal_key
          secret_id     = secret_id
        }
      ]
    ]) : binding.key => binding
  }
}

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

resource "google_service_account" "workload_identity" {
  for_each = var.enabled ? local.workload_identity_principals : {}

  project      = var.project_id
  account_id   = each.value.google_service_account_id
  display_name = coalesce(each.value.display_name, "GKE WI ${each.key}")
  description = coalesce(
    each.value.description,
    "Workload identity principal for ${each.value.kubernetes_namespace}/${each.value.kubernetes_service_account}."
  )
}

resource "google_service_account_iam_member" "workload_identity_user" {
  for_each = var.enabled ? local.workload_identity_principals : {}

  service_account_id = google_service_account.workload_identity[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value.wi_member
}

resource "google_secret_manager_secret_iam_member" "workload_secret_accessor" {
  for_each = var.enabled ? local.workload_identity_secret_access : {}

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.workload_identity[each.value.principal_key].email}"
}
