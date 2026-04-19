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

variable "labels" {
  description = "Labels applied to the service and service account."
  type        = map(string)
  default     = {}
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

variable "ingress" {
  description = "Ingress policy for the service."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
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
}

variable "secret_env" {
  description = "Secret environment variables keyed by env var name."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "cloudsql_instance_connection_names" {
  description = "Cloud SQL connection names mounted into the service."
  type        = list(string)
  default     = []
}
