variable "enabled" {
  description = "Whether to create the single-VPS stack."
  type        = bool
}

variable "project_id" {
  description = "GCP project id that owns the single-VPS stack."
  type        = string
}

variable "region" {
  description = "Region that owns the single-VPS address resources."
  type        = string
}

variable "zone" {
  description = "Zone that owns the single-VPS compute instance."
  type        = string
}

variable "instance_name" {
  description = "Name of the VM instance."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.instance_name))
    error_message = "instance_name must be 2-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "service_account_id" {
  description = "Service account id for the VM runtime identity."
  type        = string
}

variable "network_self_link" {
  description = "Self link of the VPC network used by the VM."
  type        = string
  default     = null
}

variable "subnetwork_self_link" {
  description = "Self link of the subnet used by the VM."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_image" {
  description = "Boot disk image for the VM."
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "public_source_ranges" {
  description = "CIDR ranges allowed to reach the public app ports."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to reach SSH."
  type        = set(string)
  default     = []
}

variable "frontend_port" {
  description = "Frontend TCP port exposed publicly."
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Backend TCP port exposed publicly."
  type        = number
  default     = 8080
}

variable "database_port" {
  description = "Database TCP port exposed internally on the VM."
  type        = number
  default     = 5432
}

variable "metadata" {
  description = "Metadata entries attached to the VM."
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Optional startup script executed on boot."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels applied to resources that support them."
  type        = map(string)
  default     = {}
}
