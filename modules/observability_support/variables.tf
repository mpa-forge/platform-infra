variable "environment" {
  description = "Deployment environment identifier."
  type        = string
}

variable "telemetry_profile" {
  description = "Service-facing telemetry profile."
  type        = string
}

variable "grafana_cloud_instance_id" {
  description = "Grafana Cloud stack instance id."
  type        = string
}

variable "direct_otlp_endpoint" {
  description = "Direct OTLP endpoint for Cloud Run."
  type        = string
}

variable "collector_otlp_endpoint" {
  description = "Collector endpoint for the optional GKE path."
  type        = string
}
