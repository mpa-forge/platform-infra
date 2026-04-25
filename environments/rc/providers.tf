provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_secret_manager_secret_version" "grafana_dashboard_provisioning" {
  count = (
    var.grafana_dashboard_provisioning_token == null &&
    var.grafana_dashboard_provisioning_token_secret_name != null
  ) ? 1 : 0

  project = var.project_id
  secret  = var.grafana_dashboard_provisioning_token_secret_name
  version = var.grafana_dashboard_provisioning_token_secret_version
}

locals {
  grafana_dashboard_provisioning_auth = coalesce(
    var.grafana_dashboard_provisioning_token,
    try(nonsensitive(data.google_secret_manager_secret_version.grafana_dashboard_provisioning[0].secret_data), null),
    ""
  )
}

provider "grafana" {
  url                    = var.grafana_stack_url
  auth                   = local.grafana_dashboard_provisioning_auth
  store_dashboard_sha256 = true
}
