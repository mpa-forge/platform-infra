variable "enabled" {
  description = "Whether to create the Cloud SQL baseline resources."
  type        = bool
}

variable "project_id" {
  description = "Project id that owns the Cloud SQL instance."
  type        = string
}

variable "region" {
  description = "Region for the Cloud SQL instance."
  type        = string
}

variable "instance_name" {
  description = "Cloud SQL instance name."
  type        = string
}

variable "database_name" {
  description = "Primary application database name."
  type        = string
}

variable "private_network_self_link" {
  description = "Self link of the VPC network used for private IP."
  type        = string
  default     = null
}

variable "tier" {
  description = "Instance tier for the baseline database."
  type        = string
  default     = "db-custom-1-3840"
}

variable "availability_type" {
  description = "Availability type for the instance."
  type        = string
  default     = "ZONAL"
}

variable "disk_size_gb" {
  description = "Allocated disk size in GB."
  type        = number
  default     = 20
}

variable "maintenance_window" {
  description = "Preferred maintenance window."
  type = object({
    day          = number
    hour         = number
    update_track = string
  })
  default = {
    day          = 7
    hour         = 3
    update_track = "stable"
  }
}

variable "deletion_protection" {
  description = "Whether Terraform should prevent instance destruction."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to the instance."
  type        = map(string)
  default     = {}
}
