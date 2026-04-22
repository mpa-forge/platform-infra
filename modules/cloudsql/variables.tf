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

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.instance_name))
    error_message = "instance_name must be 2-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "database_name" {
  description = "Primary application database name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must be 1-63 characters and use PostgreSQL-compatible identifier characters."
  }
}

variable "application_user_name" {
  description = "Application database user name."
  type        = string
  default     = "api"

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]{0,62}$", var.application_user_name))
    error_message = "application_user_name must be 1-63 characters and use PostgreSQL-compatible identifier characters."
  }
}

variable "application_user_password" {
  description = "Sensitive password for the application database user. Supply from a secure value source; do not commit real values."
  type        = string
  default     = null
  sensitive   = true
}

variable "application_user_password_secret_id" {
  description = "Secret Manager secret id that stores the application database user password for runtime consumers."
  type        = string
  default     = null
}

variable "private_network_self_link" {
  description = "Self link of the VPC network used for private IP."
  type        = string
  default     = null
}

variable "database_version" {
  description = "Cloud SQL PostgreSQL database version."
  type        = string
  default     = "POSTGRES_16"

  validation {
    condition     = startswith(var.database_version, "POSTGRES_")
    error_message = "database_version must be a PostgreSQL Cloud SQL version such as POSTGRES_16."
  }
}

variable "edition" {
  description = "Cloud SQL edition. Use ENTERPRISE for cost control unless ENTERPRISE_PLUS features are required."
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
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

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "disk_type" {
  description = "Storage disk type for the instance."
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_HDD", "PD_SSD"], var.disk_type)
    error_message = "disk_type must be PD_HDD or PD_SSD."
  }
}

variable "disk_size_gb" {
  description = "Allocated disk size in GB."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb must be at least 10."
  }
}

variable "disk_autoresize" {
  description = "Whether Cloud SQL may automatically increase disk size."
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Whether automated backups are enabled."
  type        = bool
  default     = true
}

variable "point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery is enabled."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "UTC time when automated backups start, in HH:MM format."
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "backup_start_time must use HH:MM 24-hour UTC format."
  }
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain PostgreSQL transaction logs for PITR."
  type        = number
  default     = 7

  validation {
    condition     = var.transaction_log_retention_days >= 1 && var.transaction_log_retention_days <= 7
    error_message = "transaction_log_retention_days must be between 1 and 7."
  }
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

  validation {
    condition = (
      var.maintenance_window.day >= 1 &&
      var.maintenance_window.day <= 7 &&
      var.maintenance_window.hour >= 0 &&
      var.maintenance_window.hour <= 23 &&
      contains(["canary", "stable", "week5"], var.maintenance_window.update_track)
    )
    error_message = "maintenance_window must use day 1-7, hour 0-23, and update_track canary, stable, or week5."
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

  validation {
    condition = alltrue([
      for key, value in var.labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
      can(regex("^[a-z0-9_-]{0,63}$", value))
    ])
    error_message = "labels must use lowercase GCP label keys and values."
  }
}

variable "database_flags" {
  description = "PostgreSQL database flags to apply to the instance."
  type        = map(string)
  default     = {}
}
