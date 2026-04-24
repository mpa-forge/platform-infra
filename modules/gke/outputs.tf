output "cluster_name" {
  description = "GKE cluster name."
  value       = try(google_container_cluster.this[0].name, null)
}

output "cluster_endpoint" {
  description = "Cluster control-plane endpoint."
  value       = try(google_container_cluster.this[0].endpoint, null)
}

output "workload_pool" {
  description = "Workload identity pool used by this cluster."
  value       = var.enabled ? "${var.project_id}.svc.id.goog" : null
}

output "workload_identity_principals" {
  description = "Workload identity principal metadata keyed by logical principal name."
  value = {
    for principal_key, principal in var.workload_identity_principals :
    principal_key => {
      google_service_account_email = try(google_service_account.workload_identity[principal_key].email, null)
      google_service_account_id    = principal.google_service_account_id
      kubernetes_namespace         = principal.kubernetes_namespace
      kubernetes_service_account   = principal.kubernetes_service_account
      workload_identity_member = format(
        "serviceAccount:%s[%s/%s]",
        "${var.project_id}.svc.id.goog",
        principal.kubernetes_namespace,
        principal.kubernetes_service_account
      )
      secret_ids = sort(tolist(principal.secret_ids))
    }
  }
}

output "eso_secret_mappings" {
  description = "ESO-ready secret mapping metadata keyed by logical secret name."
  value = {
    for logical_name, mapping in var.eso_secret_mappings :
    logical_name => {
      secret_id              = mapping.secret_id
      kubernetes_namespace   = mapping.kubernetes_namespace
      kubernetes_secret_name = mapping.kubernetes_secret_name
      kubernetes_secret_key  = mapping.kubernetes_secret_key
      version                = mapping.version
    }
  }
}
