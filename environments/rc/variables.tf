variable "environment" {
  description = "Environment identifier."
  type        = string
  default     = "rc"
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

variable "deployment_enabled" {
  description = "Whether the selected deployment preset should create infrastructure."
  type        = bool
  default     = false
}

variable "deployment_preset" {
  description = "Deployment preset that selects the runtime topology for RC."
  type        = string
  default     = "single-vps"

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
  description = "Optional externally managed frontend URL for RC presets that do not provision the frontend here."
  type        = string
  default     = null
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
  default     = "https://auth.rc.example.invalid"
}

variable "api_auth_audience" {
  description = "Authentication audience accepted by the API runtime."
  type        = string
  default     = "platform-blueprint-api-rc"
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
  description = "Zone used by the RC single-vps preset."
  type        = string
  default     = "us-east4-b"
}

variable "vps_machine_type" {
  description = "Machine type used by the RC single-vps preset."
  type        = string
  default     = "e2-medium"
}

variable "vps_boot_disk_image" {
  description = "Boot disk image used by the RC single-vps preset."
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "vps_boot_disk_size_gb" {
  description = "Boot disk size in GB used by the RC single-vps preset."
  type        = number
  default     = 30
}

variable "vps_allow_public_source_ranges" {
  description = "CIDR ranges allowed to reach the public frontend and backend ports on the RC single VPS."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "vps_allow_ssh_source_ranges" {
  description = "CIDR ranges allowed to reach SSH on the RC single VPS."
  type        = set(string)
  default     = ["35.235.240.0/20"]
}

variable "vps_frontend_port" {
  description = "Frontend port exposed by the RC single-vps preset."
  type        = number
  default     = 80
}

variable "vps_backend_port" {
  description = "Backend port exposed by the RC single-vps preset."
  type        = number
  default     = 8080
}

variable "vps_database_port" {
  description = "Database port exposed internally by the RC single-vps preset."
  type        = number
  default     = 5432
}

variable "vps_startup_script" {
  description = "Optional startup script for the RC single-vps preset."
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

variable "grafana_stack_url" {
  description = "Grafana Cloud stack URL used by the dashboard provisioning provider."
  type        = string
  default     = "https://miquelpizaairas.grafana.net"
}

variable "grafana_dashboard_folder_title" {
  description = "Grafana folder title for the baseline dashboard set."
  type        = string
  default     = "Platform / RC"
}

variable "grafana_dashboard_folder_uid" {
  description = "Stable Grafana folder UID for the baseline dashboard set."
  type        = string
  default     = "platform-rc"
}

variable "grafana_dashboard_manifest_path" {
  description = "Optional absolute path override for the Grafana dashboard manifest."
  type        = string
  default     = null
}

variable "grafana_dashboard_source_root" {
  description = "Optional absolute repository root override used to resolve Grafana dashboard asset paths."
  type        = string
  default     = null
}

variable "grafana_dashboard_provisioning_token" {
  description = "Optional Grafana API token used to provision dashboard folders and dashboards."
  type        = string
  default     = null
  sensitive   = true
}

variable "grafana_dashboard_provisioning_token_secret_name" {
  description = "Optional Secret Manager secret name that stores the Grafana dashboard provisioning token."
  type        = string
  default     = null
}

variable "grafana_dashboard_provisioning_token_secret_version" {
  description = "Secret version used when resolving the Grafana dashboard provisioning token from Secret Manager."
  type        = string
  default     = "latest"
}

variable "gke_collector_otlp_endpoint" {
  description = "Collector endpoint for the optional GKE path."
  type        = string
  default     = "http://otel-collector.platform-rc.svc.cluster.local:4318"
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
