output "cluster_name" {
  description = "GKE cluster name."
  value       = try(google_container_cluster.this[0].name, null)
}

output "cluster_endpoint" {
  description = "Cluster control-plane endpoint."
  value       = try(google_container_cluster.this[0].endpoint, null)
}
