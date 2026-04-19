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
    ci_push_members      = optional(set(string), [])
    runtime_pull_members = optional(set(string), [])
  }))
  default = {}
}
