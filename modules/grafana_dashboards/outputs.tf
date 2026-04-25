output "folder" {
  description = "Provisioned Grafana folder metadata for the baseline dashboard set."
  value = {
    id    = grafana_folder.baseline.id
    uid   = grafana_folder.baseline.uid
    title = grafana_folder.baseline.title
    url   = grafana_folder.baseline.url
  }
}

output "dashboards" {
  description = "Provisioned baseline dashboard metadata keyed by source file."
  value = {
    for source_file, dashboard in grafana_dashboard.baseline :
    source_file => {
      id    = dashboard.id
      uid   = dashboard.uid
      url   = dashboard.url
      title = local.dashboards[source_file].title
      file  = local.dashboards[source_file].source_path
    }
  }
}
