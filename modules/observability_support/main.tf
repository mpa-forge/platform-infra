locals {
  telemetry_enabled         = var.telemetry_profile != "off"
  grafana_token_secret_name = local.telemetry_enabled ? "grafana-otlp-ingest-token-${var.environment}" : null

  cloud_run_env = {
    OTEL_MODE                   = local.telemetry_enabled ? "direct_otlp" : "disabled"
    OBS_TELEMETRY_PROFILE       = var.telemetry_profile
    OTEL_EXPORTER_OTLP_ENDPOINT = local.telemetry_enabled ? var.direct_otlp_endpoint : ""
    GRAFANA_CLOUD_INSTANCE_ID   = local.telemetry_enabled ? var.grafana_cloud_instance_id : ""
  }

  gke_env = {
    OTEL_MODE                   = local.telemetry_enabled ? "collector_gateway" : "disabled"
    OBS_TELEMETRY_PROFILE       = var.telemetry_profile
    OTEL_EXPORTER_OTLP_ENDPOINT = local.telemetry_enabled ? var.collector_otlp_endpoint : ""
    GRAFANA_CLOUD_INSTANCE_ID   = local.telemetry_enabled ? var.grafana_cloud_instance_id : ""
  }
}
