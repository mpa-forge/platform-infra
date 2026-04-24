variable "enabled" {
  description = "Whether to create Secret Manager placeholders and bindings."
  type        = bool
}

variable "project_id" {
  description = "Project id that owns the secrets."
  type        = string
}

variable "environment" {
  description = "Optional environment identifier used to validate environment-scoped secret ids."
  type        = string
  default     = null

  validation {
    condition     = var.environment == null || can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must be null or use lowercase letters, digits, and hyphens."
  }
}

variable "catalog_name" {
  description = "Logical name for the reusable runtime secret catalog exposed by this module."
  type        = string
  default     = "runtime"

  validation {
    condition     = trimspace(var.catalog_name) != ""
    error_message = "catalog_name must not be empty."
  }
}

variable "labels" {
  description = "Labels applied to the secret metadata."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret definitions keyed by logical name."
  type = map(object({
    secret_id              = string
    accessors              = optional(set(string), [])
    annotations            = optional(map(string), {})
    labels                 = optional(map(string), {})
    cloud_run_env_var      = optional(string)
    eso_enabled            = optional(bool, true)
    eso_target_secret_name = optional(string)
    eso_target_secret_key  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for logical_name, secret in var.secrets :
      trimspace(logical_name) != "" && trimspace(secret.secret_id) != ""
    ])
    error_message = "secrets must use non-empty logical names and secret_id values."
  }

  validation {
    condition = alltrue(flatten([
      for secret in values(var.secrets) : [
        for member in secret.accessors :
        trimspace(member) != ""
      ]
    ]))
    error_message = "secrets accessors must not contain empty members."
  }

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      try(secret.cloud_run_env_var, null) == null || can(regex("^[A-Z][A-Z0-9_]*$", secret.cloud_run_env_var))
    ])
    error_message = "cloud_run_env_var must be null or use the Cloud Run env-var format /^[A-Z][A-Z0-9_]*$/."
  }

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      try(secret.eso_target_secret_name, null) == null || trimspace(secret.eso_target_secret_name) != ""
    ])
    error_message = "eso_target_secret_name must be null or a non-empty string."
  }

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      try(secret.eso_target_secret_key, null) == null || trimspace(secret.eso_target_secret_key) != ""
    ])
    error_message = "eso_target_secret_key must be null or a non-empty string."
  }
}
