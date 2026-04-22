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

  validation {
    condition     = !var.module_activation.cloudsql || var.module_activation.network
    error_message = "module_activation.network must be true when module_activation.cloudsql is true."
  }

  validation {
    condition     = !var.module_activation.gke || var.module_activation.network
    error_message = "module_activation.network must be true when module_activation.gke is true."
  }

  validation {
    condition     = !var.module_activation.cloudrun_api || var.module_activation.secrets
    error_message = "module_activation.secrets must be true when module_activation.cloudrun_api is true."
  }
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

variable "api_log_level" {
  description = "Log level injected into the API runtime."
  type        = string
  default     = "info"
}

variable "api_container_port" {
  description = "HTTP port exposed by the API container."
  type        = number
  default     = 8080
}

variable "api_auth_issuer_url" {
  description = "Authentication issuer URL accepted by the API runtime."
  type        = string
  default     = "https://auth.prod.example.invalid"
}

variable "api_auth_audience" {
  description = "Authentication audience accepted by the API runtime."
  type        = string
  default     = "platform-blueprint-api-prod"
}

variable "api_database_user" {
  description = "Database user name used in the API DATABASE_URL."
  type        = string
  default     = "platform_api"
}

variable "api_min_instance_count" {
  description = "Minimum Cloud Run API instances."
  type        = number
  default     = 0
}

variable "api_max_instance_count" {
  description = "Maximum Cloud Run API instances."
  type        = number
  default     = 10
}

variable "api_max_instance_request_concurrency" {
  description = "Maximum requests per Cloud Run API instance."
  type        = number
  default     = 80
}

variable "api_allow_unauthenticated" {
  description = "Whether the Cloud Run API service grants allUsers invoker."
  type        = bool
  default     = false
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
