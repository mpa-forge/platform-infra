variable "enabled" {
  description = "Whether to create the shared VPC baseline for the environment."
  type        = bool
}

variable "project_id" {
  description = "GCP project id that owns the network resources."
  type        = string
}

variable "region" {
  description = "Primary deployment region for regional infrastructure."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the primary subnet."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the primary subnet."
  type        = string
}

variable "private_service_access_prefix_length" {
  description = "Prefix length for the reserved private service access range."
  type        = number
  default     = 16
}

variable "labels" {
  description = "Labels applied to resources that support them."
  type        = map(string)
  default     = {}
}
