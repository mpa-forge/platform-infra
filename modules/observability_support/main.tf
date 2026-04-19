locals {
  grafana_token_secret_name = "grafana-otlp-ingest-token-${var.environment}"

  cloud_run_env = {
    OTEL_MODE                   = "direct_otlp"
    OBS_TELEMETRY_PROFILE       = var.telemetry_profile
    OTEL_EXPORTER_OTLP_ENDPOINT = var.direct_otlp_endpoint
    GRAFANA_CLOUD_INSTANCE_ID   = var.grafana_cloud_instance_id
  }

  gke_env = {
    OTEL_MODE                   = "collector_gateway"
    OBS_TELEMETRY_PROFILE       = var.telemetry_profile
    OTEL_EXPORTER_OTLP_ENDPOINT = var.collector_otlp_endpoint
    GRAFANA_CLOUD_INSTANCE_ID   = var.grafana_cloud_instance_id
  }
}
