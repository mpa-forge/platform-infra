locals {
  normalized_secrets = {
    for logical_name, secret in var.secrets : logical_name => {
      logical_name           = logical_name
      secret_id              = secret.secret_id
      accessors              = sort(tolist(secret.accessors))
      annotations            = secret.annotations
      labels                 = merge(var.labels, secret.labels)
      cloud_run_env_var      = try(secret.cloud_run_env_var, null)
      eso_enabled            = try(secret.eso_enabled, true)
      eso_target_secret_name = coalesce(try(secret.eso_target_secret_name, null), secret.secret_id)
      eso_target_secret_key  = coalesce(try(secret.eso_target_secret_key, null), try(secret.cloud_run_env_var, null), logical_name)
      secret_name            = "projects/${var.project_id}/secrets/${secret.secret_id}"
    }
  }

  accessor_bindings = length(local.normalized_secrets) == 0 ? {} : merge([
    for logical_name, secret in local.normalized_secrets : {
      for member in secret.accessors :
      "${logical_name}|${member}" => {
        logical_name = logical_name
        member       = member
      }
    }
  ]...)

  secret_catalog = {
    for logical_name, secret in local.normalized_secrets : logical_name => {
      catalog_name = var.catalog_name
      environment  = var.environment
      project_id   = var.project_id
      managed      = var.enabled
      logical_name = logical_name
      secret_id    = secret.secret_id
      secret_name  = secret.secret_name
      labels       = secret.labels
      annotations  = secret.annotations
      accessors    = secret.accessors
      cloud_run = secret.cloud_run_env_var == null ? null : {
        env_var     = secret.cloud_run_env_var
        secret_id   = secret.secret_id
        secret_name = secret.secret_name
      }
      eso = secret.eso_enabled ? {
        remote_ref_key     = secret.secret_id
        target_secret_name = secret.eso_target_secret_name
        target_secret_key  = secret.eso_target_secret_key
      } : null
    }
  }

  cloud_run_secret_catalog = {
    for logical_name, secret in local.secret_catalog :
    secret.cloud_run.env_var => {
      logical_name = logical_name
      env_var      = secret.cloud_run.env_var
      secret_id    = secret.secret_id
      secret_name  = secret.secret_name
    }
    if secret.cloud_run != null
  }

  eso_secret_catalog = {
    for logical_name, secret in local.secret_catalog : logical_name => {
      logical_name       = logical_name
      secret_id          = secret.secret_id
      secret_name        = secret.secret_name
      remote_ref_key     = secret.eso.remote_ref_key
      target_secret_name = secret.eso.target_secret_name
      target_secret_key  = secret.eso.target_secret_key
      cloud_run_env_var  = try(secret.cloud_run.env_var, null)
    }
    if secret.eso != null
  }
}

check "environment_scoped_secret_ids" {
  assert {
    condition = var.environment == null || alltrue([
      for secret in values(local.normalized_secrets) :
      endswith(secret.secret_id, "-${var.environment}")
    ])
    error_message = "When environment is set, each secret_id must end with -<environment> to preserve environment-scoped naming."
  }
}

resource "google_secret_manager_secret" "this" {
  for_each = var.enabled ? local.normalized_secrets : {}

  project   = var.project_id
  secret_id = each.value.secret_id
  labels    = each.value.labels

  replication {
    auto {}
  }

  annotations = each.value.annotations
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = var.enabled ? local.accessor_bindings : {}

  project   = var.project_id
  secret_id = local.normalized_secrets[each.value.logical_name].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}
