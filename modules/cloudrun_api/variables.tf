variable "enabled" {
  description = "Whether to create the Cloud Run API baseline."
  type        = bool
}

variable "project_id" {
  description = "Project id that owns the Cloud Run service."
  type        = string
}

variable "region" {
  description = "Cloud Run region."
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
}

variable "service_account_id" {
  description = "Service account id for the API runtime."
  type        = string
}

variable "container_image" {
  description = "Container image reference for the API service."
  type        = string
}

variable "runtime_path" {
  description = "Selected API runtime path represented in container env."
  type        = string
  default     = "cloud_run"

  validation {
    condition     = contains(["cloud_run"], var.runtime_path)
    error_message = "Cloud Run API module runtime_path must be cloud_run."
  }
}

variable "labels" {
  description = "Labels applied to the service and service account."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Annotations applied to the Cloud Run service."
  type        = map(string)
  default     = {}
}

variable "template_annotations" {
  description = "Annotations applied to new Cloud Run revisions."
  type        = map(string)
  default     = {}
}

variable "launch_stage" {
  description = "Cloud Run launch stage annotation value."
  type        = string
  default     = "GA"
}

variable "min_instance_count" {
  description = "Minimum number of instances to keep warm."
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances."
  type        = number
  default     = 3
}

variable "max_instance_request_concurrency" {
  description = "Request concurrency per instance."
  type        = number
  default     = 80
}

variable "timeout" {
  description = "Request timeout."
  type        = string
  default     = "300s"
}

variable "container_port" {
  description = "Container port exposed by the API runtime."
  type        = number
  default     = 8080
}

variable "ingress" {
  description = "Ingress policy for the service."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}

variable "allow_unauthenticated" {
  description = "Whether to grant public unauthenticated invocation to allUsers."
  type        = bool
  default     = false
}

variable "container_limits" {
  description = "Container resource limits."
  type        = map(string)
  default = {
    cpu    = "1"
    memory = "512Mi"
  }
}

variable "plain_env" {
  description = "Plain environment variables injected into the container."
  type        = map(string)
  default     = {}

  validation {
    condition = !var.enabled || alltrue([
      for name in [
        "APP_ENV",
        "LOG_LEVEL",
        "HTTP_PORT",
        "DB_HOST",
        "DB_NAME",
        "DB_USER",
        "AUTH_ISSUER_URL",
        "AUTH_AUDIENCE",
        "API_RUNTIME_PATH",
        "OTEL_MODE",
        "OBS_TELEMETRY_PROFILE",
        "OTEL_EXPORTER_OTLP_ENDPOINT",
        "GRAFANA_CLOUD_INSTANCE_ID"
      ] : contains(keys(var.plain_env), name)
    ])
    error_message = "plain_env must include the backend API Cloud Run startup environment contract when enabled."
  }
}

variable "secret_env" {
  description = "Secret environment variables keyed by env var name."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}

  validation {
    condition = !var.enabled || alltrue([
      for name in [
        "DB_PASSWORD",
        "GRAFANA_OTLP_INGEST_TOKEN"
      ] : contains(keys(var.secret_env), name)
    ])
    error_message = "secret_env must include DB_PASSWORD and GRAFANA_OTLP_INGEST_TOKEN when enabled."
  }

  validation {
    condition = !var.enabled || alltrue([
      for env_name, secret_ref in var.secret_env :
      trim(env_name) != "" && trim(secret_ref.secret) != "" && trim(secret_ref.version) != ""
    ])
    error_message = "secret_env entries must use non-empty env var names, secret names, and versions."
  }
}

variable "runtime_secret_access_env_names" {
  description = "Explicit secret env var names that receive Secret Manager accessor IAM for least-privilege runtime access."
  type        = set(string)
  default = [
    "DB_PASSWORD",
    "GRAFANA_OTLP_INGEST_TOKEN"
  ]

  validation {
    condition = !var.enabled || alltrue([
      for name in [
        "DB_PASSWORD",
        "GRAFANA_OTLP_INGEST_TOKEN"
      ] : contains(var.runtime_secret_access_env_names, name)
    ])
    error_message = "runtime_secret_access_env_names must include DB_PASSWORD and GRAFANA_OTLP_INGEST_TOKEN when enabled."
  }

  validation {
    condition = !var.enabled || alltrue([
      for name in var.runtime_secret_access_env_names : contains(keys(var.secret_env), name)
    ])
    error_message = "runtime_secret_access_env_names can only reference env vars defined in secret_env."
  }
}

variable "cloudsql_instance_connection_names" {
  description = "Cloud SQL connection names mounted into the service."
  type        = list(string)
  default     = []
}

variable "cloudsql_enabled" {
  description = "Whether to attach Cloud SQL socket volumes and grant Cloud SQL client IAM."
  type        = bool
  default     = false
}

variable "cloudsql_mount_path" {
  description = "Mount path for Cloud SQL Unix sockets."
  type        = string
  default     = "/cloudsql"
}

variable "startup_probe_path" {
  description = "HTTP path used by the Cloud Run startup probe."
  type        = string
  default     = "/readyz"
}

variable "startup_probe_initial_delay_seconds" {
  description = "Initial delay for the startup probe."
  type        = number
  default     = 0
}

variable "startup_probe_period_seconds" {
  description = "Period between startup probe attempts."
  type        = number
  default     = 10
}

variable "startup_probe_timeout_seconds" {
  description = "Startup probe timeout."
  type        = number
  default     = 5
}

variable "startup_probe_failure_threshold" {
  description = "Startup probe failure threshold."
  type        = number
  default     = 12
}
