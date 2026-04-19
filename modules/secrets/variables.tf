variable "enabled" {
  description = "Whether to create Secret Manager placeholders and bindings."
  type        = bool
}

variable "project_id" {
  description = "Project id that owns the secrets."
  type        = string
}

variable "labels" {
  description = "Labels applied to the secret metadata."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret definitions keyed by logical name."
  type = map(object({
    secret_id   = string
    accessors   = optional(set(string), [])
    annotations = optional(map(string), {})
  }))
  default = {}
}
