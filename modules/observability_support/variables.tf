variable "environment" {
  description = "Deployment environment identifier."
  type        = string
}

variable "telemetry_profile" {
  description = "Service-facing telemetry profile."
  type        = string

  validation {
    condition     = contains(["off", "minimal", "balanced"], var.telemetry_profile)
    error_message = "telemetry_profile must be one of off, minimal, or balanced."
  }
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
