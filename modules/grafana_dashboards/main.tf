locals {
  manifest = jsondecode(file(var.dashboard_manifest_path))

  dashboards = {
    for dashboard in try(local.manifest.dashboards, []) :
    dashboard.file => merge(dashboard, {
      source_path = abspath("${var.dashboard_source_root}/${dashboard.file}")
    })
  }
}

resource "grafana_folder" "baseline" {
  title                        = var.folder_title
  uid                          = var.folder_uid
  prevent_destroy_if_not_empty = var.prevent_destroy_if_not_empty
}

resource "grafana_dashboard" "baseline" {
  for_each = local.dashboards

  folder      = grafana_folder.baseline.id
  config_json = file(each.value.source_path)
  overwrite   = true
}
