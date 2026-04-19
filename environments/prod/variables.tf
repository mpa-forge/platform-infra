variable "environment" {
  description = "Environment identifier."
  type        = string
  default     = "prod"
}

variable "project_id" {
  description = "Primary GCP project id for the environment."
  type        = string
}

variable "state_project_id" {
  description = "Dedicated Terraform state project id."
  type        = string
}

variable "region" {
  description = "Primary deployment region."
  type        = string
  default     = "us-east4"
}

variable "module_activation" {
  description = "Per-module creation toggles for the skeleton root."
  type = object({
    network      = bool
    gar          = bool
    cloudsql     = bool
    secrets      = bool
    cloudrun_api = bool
    gke          = bool
  })
}

variable "network_name" {
  description = "VPC network name."
  type        = string
}

variable "subnet_name" {
  description = "Primary subnet name."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR."
  type        = string
}

variable "private_service_access_prefix_length" {
  description = "Private service access prefix length."
  type        = number
  default     = 16
}

variable "api_container_image" {
  description = "Immutable container image reference for the API baseline."
  type        = string
}

variable "telemetry_profile" {
  description = "Default telemetry profile for the API service."
  type        = string
  default     = "balanced"
}

variable "grafana_cloud_instance_id" {
  description = "Grafana Cloud stack instance id."
  type        = string
  default     = "1546554"
}

variable "grafana_direct_otlp_endpoint" {
  description = "Grafana Cloud direct OTLP endpoint."
  type        = string
  default     = "https://otlp-gateway-prod-us-east-3.grafana.net/otlp"
}

variable "gke_collector_otlp_endpoint" {
  description = "Collector endpoint for the optional GKE path."
  type        = string
  default     = "http://otel-collector.platform-prod.svc.cluster.local:4318"
}
