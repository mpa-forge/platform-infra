variable "environment" {
  description = "Deployment environment identifier."
  type        = string
}

variable "dashboard_manifest_path" {
  description = "Absolute path to the source-controlled dashboard manifest."
  type        = string
}

variable "dashboard_source_root" {
  description = "Absolute repository root used to resolve manifest dashboard file paths."
  type        = string
}

variable "folder_title" {
  description = "Grafana folder title that will contain the baseline dashboards."
  type        = string
}

variable "folder_uid" {
  description = "Stable Grafana folder UID for the environment baseline dashboards."
  type        = string
}

variable "prevent_destroy_if_not_empty" {
  description = "Whether Terraform should block folder deletion while dashboards still exist in it."
  type        = bool
  default     = false
}
