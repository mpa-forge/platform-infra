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
