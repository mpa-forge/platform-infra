variable "enabled" {
  description = "Whether to create the optional GKE Autopilot cluster."
  type        = bool
}

variable "project_id" {
  description = "Project id that owns the GKE cluster."
  type        = string
}

variable "region" {
  description = "Regional location for the GKE cluster."
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
}

variable "network_self_link" {
  description = "Self link of the VPC network."
  type        = string
  default     = null
}

variable "subnetwork_self_link" {
  description = "Self link of the primary subnet."
  type        = string
  default     = null
}

variable "release_channel" {
  description = "Preferred GKE release channel."
  type        = string
  default     = "REGULAR"
}

variable "deletion_protection" {
  description = "Whether to prevent Terraform from destroying the cluster."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to the cluster."
  type        = map(string)
  default     = {}
}

variable "workload_identity_principals" {
  description = "Optional workload identity principals that need GSM access through GKE."
  type = map(object({
    google_service_account_id  = string
    kubernetes_namespace       = string
    kubernetes_service_account = string
    secret_ids                 = optional(set(string), [])
    display_name               = optional(string, null)
    description                = optional(string, null)
  }))
  default = {}
}

variable "eso_secret_mappings" {
  description = "Optional ESO-facing mapping metadata keyed by logical secret name."
  type = map(object({
    secret_id              = string
    kubernetes_namespace   = string
    kubernetes_secret_name = string
    kubernetes_secret_key  = string
    version                = optional(string, "latest")
  }))
  default = {}
}
