variable "enabled" {
  description = "Whether to create GAR repositories and IAM bindings."
  type        = bool
}

variable "project_id" {
  description = "GCP project id that owns the repositories."
  type        = string
}

variable "region" {
  description = "Region for the Artifact Registry repositories."
  type        = string
}

variable "labels" {
  description = "Labels applied to each repository."
  type        = map(string)
  default     = {}
}

variable "repositories" {
  description = "Repository definitions keyed by repository id."
  type = map(object({
    description          = string
    format               = optional(string, "DOCKER")
    image_names          = optional(set(string), [])
    ci_push_members      = optional(set(string), [])
    runtime_pull_members = optional(set(string), [])
    cleanup_policies = optional(map(object({
      action = string
      condition = optional(object({
        tag_state             = optional(string)
        tag_prefixes          = optional(list(string))
        version_name_prefixes = optional(list(string))
        package_name_prefixes = optional(list(string))
        older_than            = optional(string)
        newer_than            = optional(string)
      }))
      most_recent_versions = optional(object({
        keep_count            = optional(number)
        package_name_prefixes = optional(list(string))
      }))
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for repository_id in keys(var.repositories) :
      can(regex("^[a-z][a-z0-9-]{0,62}$", repository_id))
    ])
    error_message = "GAR repository ids must be lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}
