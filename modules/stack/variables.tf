variable "environment" {
  description = "Environment identifier."
  type        = string
}

variable "state_project_id" {
  description = "Dedicated Terraform state project id."
  type        = string
}

variable "project_id" {
  description = "Primary GCP project id for the environment."
  type        = string
}

variable "region" {
  description = "Primary deployment region."
  type        = string
  default     = "us-east4"
}

variable "deployment_enabled" {
  description = "Whether the selected deployment preset should create infrastructure."
  type        = bool
  default     = false
}

variable "deployment_preset" {
  description = "Deployment preset that selects the runtime topology for this environment."
  type        = string

  validation {
    condition = contains([
      "single-vps",
      "cloudrun-cloudsql",
      "cloudrun-cdn-cloudsql",
      "gke-cloudsql",
    ], var.deployment_preset)
    error_message = "deployment_preset must be one of single-vps, cloudrun-cloudsql, cloudrun-cdn-cloudsql, or gke-cloudsql."
  }
}

variable "frontend_public_url" {
  description = "Optional externally managed frontend URL for presets that do not provision the frontend here."
  type        = string
  default     = null

  validation {
    condition     = var.frontend_public_url == null || trimspace(var.frontend_public_url) != ""
    error_message = "frontend_public_url must be null or a non-empty string."
  }
}

variable "ai_worker_lanes" {
  description = "AI worker lane definitions that need runtime identities and secret catalog entries."
  type = map(object({
    target_repo          = string
    service_account_id   = optional(string)
    github_pat_secret_id = optional(string)
    agent_key_secret_id  = optional(string)
    agent_key_enabled    = optional(bool, false)
  }))
  default = {}
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

variable "gar_ci_push_members" {
  description = "Repository-scoped CI principals that can push images, keyed by GAR repository id."
  type        = map(set(string))
  default = {
    apps    = []
    workers = []
    tools   = []
  }
}

variable "gar_worker_runtime_pull_members" {
  description = "Additional worker runtime principals that can pull worker images."
  type        = set(string)
  default     = []
}

variable "gar_tool_runtime_pull_members" {
  description = "Additional runtime principals that can pull tool images."
  type        = set(string)
  default     = []
}

variable "gar_untagged_retention" {
  description = "Duration after which untagged GAR artifacts are pruned."
  type        = string
  default     = "604800s"
}

variable "gar_sha_tagged_retention" {
  description = "Duration after which old SHA-tagged GAR artifacts are pruned."
  type        = string
  default     = "2592000s"
}

variable "gar_sha_keep_count" {
  description = "Minimum recent SHA-tagged image versions retained per repository."
  type        = number
  default     = 20
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
}

variable "api_auth_audience" {
  description = "Authentication audience accepted by the API runtime."
  type        = string
}

variable "api_database_user" {
  description = "Database user name used by the API split database env contract."
  type        = string
  default     = "platform_api"
}

variable "api_database_password" {
  description = "Sensitive password for the API database user. Supply through a secure operator or CI variable, never terraform.tfvars."
  type        = string
  default     = null
  sensitive   = true
}

variable "vps_zone" {
  description = "Zone used by the single-vps preset."
  type        = string
  default     = "us-east4-b"
}

variable "vps_machine_type" {
  description = "Machine type used by the single-vps preset."
  type        = string
  default     = "e2-medium"
}

variable "vps_boot_disk_image" {
  description = "Boot disk image used by the single-vps preset."
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "vps_boot_disk_size_gb" {
  description = "Boot disk size in GB used by the single-vps preset."
  type        = number
  default     = 30

  validation {
    condition     = var.vps_boot_disk_size_gb >= 10
    error_message = "vps_boot_disk_size_gb must be at least 10 GB."
  }
}

variable "vps_allow_public_source_ranges" {
  description = "CIDR ranges allowed to reach the public frontend and backend ports on the single VPS."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "vps_allow_ssh_source_ranges" {
  description = "CIDR ranges allowed to reach SSH on the single VPS."
  type        = set(string)
  default     = ["35.235.240.0/20"]
}

variable "vps_frontend_port" {
  description = "Frontend port exposed by the single-vps preset."
  type        = number
  default     = 80

  validation {
    condition     = var.vps_frontend_port >= 1 && var.vps_frontend_port <= 65535
    error_message = "vps_frontend_port must be between 1 and 65535."
  }
}

variable "vps_backend_port" {
  description = "Backend port exposed by the single-vps preset."
  type        = number
  default     = 8080

  validation {
    condition     = var.vps_backend_port >= 1 && var.vps_backend_port <= 65535
    error_message = "vps_backend_port must be between 1 and 65535."
  }
}

variable "vps_database_port" {
  description = "Database port exposed internally by the single-vps preset."
  type        = number
  default     = 5432

  validation {
    condition     = var.vps_database_port >= 1 && var.vps_database_port <= 65535
    error_message = "vps_database_port must be between 1 and 65535."
  }
}

variable "vps_startup_script" {
  description = "Optional startup script for the single-vps preset."
  type        = string
  default     = null
}

variable "cloudsql_profile" {
  description = "Named Cloud SQL cost and durability profile: super_cheap, cheap_dev, rc, or prod."
  type        = string
  default     = "super_cheap"

  validation {
    condition     = contains(["super_cheap", "cheap_dev", "rc", "prod"], var.cloudsql_profile)
    error_message = "cloudsql_profile must be one of super_cheap, cheap_dev, rc, or prod."
  }
}

variable "api_min_instance_count" {
  description = "Minimum Cloud Run API instances."
  type        = number
  default     = 0
}

variable "api_max_instance_count" {
  description = "Maximum Cloud Run API instances."
  type        = number
  default     = 3
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
}

variable "gke_cluster_secret_store_name" {
  description = "ClusterSecretStore name that Phase 6 should use for GSM-backed ESO sync."
  type        = string
  default     = "gcp-secret-manager"
}

variable "gke_external_secrets_namespace" {
  description = "Namespace that will host the External Secrets Operator controller."
  type        = string
  default     = "external-secrets"
}

variable "gke_external_secrets_service_account_name" {
  description = "Kubernetes service account name for the External Secrets Operator controller."
  type        = string
  default     = "external-secrets"
}

variable "gke_api_namespace" {
  description = "Namespace for the backend API workload on the optional GKE path."
  type        = string
  default     = "platform-blueprint"
}

variable "gke_api_service_account_name" {
  description = "Kubernetes service account name for the backend API workload on the optional GKE path."
  type        = string
  default     = "backend-api"
}
