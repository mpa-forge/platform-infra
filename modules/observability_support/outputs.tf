output "grafana_token_secret_name" {
  description = "Secret Manager secret name that stores the Grafana ingest token."
  value       = local.grafana_token_secret_name
}

output "telemetry_enabled" {
  description = "Whether telemetry wiring should create the Grafana secret-backed runtime contract."
  value       = local.telemetry_enabled
}

output "cloud_run_env" {
  description = "Plain Cloud Run environment variables for direct OTLP delivery."
  value       = local.cloud_run_env
}

output "cloud_run_secret_env" {
  description = "Cloud Run secret environment variables."
  value = local.telemetry_enabled ? {
    GRAFANA_OTLP_INGEST_TOKEN = {
      secret  = local.grafana_token_secret_name
      version = "latest"
    }
  } : {}
}

output "gke_env" {
  description = "Workload-facing environment variables for the optional GKE path."
  value       = local.gke_env
}
