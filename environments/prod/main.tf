locals {
  labels = {
    env        = var.environment
    project    = "platform-blueprint"
    service    = "platform-infra"
    managed_by = "terraform"
    region     = var.region
  }

  api_service_name       = "api-${var.environment}"
  api_service_account_id = "api-${var.environment}-sa"
  api_service_account    = "serviceAccount:${local.api_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
  db_instance_name       = "platform-${var.environment}-db"
  db_name                = "platform_${var.environment}"
  db_password_secret_id  = "api-db-password-${var.environment}"
  gke_cluster_name       = "platform-${var.environment}"
  cloudsql_profiles = {
    super_cheap = {
      edition                        = "ENTERPRISE"
      tier                           = "db-f1-micro"
      availability_type              = "ZONAL"
      disk_type                      = "PD_HDD"
      disk_size_gb                   = 10
      disk_autoresize                = true
      backup_enabled                 = false
      point_in_time_recovery_enabled = false
      transaction_log_retention_days = 1
      backup_start_time              = "03:00"
      maintenance_window             = { day = 7, hour = 3, update_track = "stable" }
    }
    cheap_dev = {
      edition                        = "ENTERPRISE"
      tier                           = "db-g1-small"
      availability_type              = "ZONAL"
      disk_type                      = "PD_HDD"
      disk_size_gb                   = 10
      disk_autoresize                = true
      backup_enabled                 = true
      point_in_time_recovery_enabled = false
      transaction_log_retention_days = 1
      backup_start_time              = "03:00"
      maintenance_window             = { day = 7, hour = 3, update_track = "stable" }
    }
    rc = {
      edition                        = "ENTERPRISE"
      tier                           = "db-custom-1-3840"
      availability_type              = "ZONAL"
      disk_type                      = "PD_SSD"
      disk_size_gb                   = 20
      disk_autoresize                = true
      backup_enabled                 = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_start_time              = "03:00"
      maintenance_window             = { day = 7, hour = 3, update_track = "stable" }
    }
    prod = {
      edition                        = "ENTERPRISE"
      tier                           = "db-custom-2-7680"
      availability_type              = "REGIONAL"
      disk_type                      = "PD_SSD"
      disk_size_gb                   = 50
      disk_autoresize                = true
      backup_enabled                 = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_start_time              = "03:00"
      maintenance_window             = { day = 7, hour = 3, update_track = "stable" }
    }
  }
  cloudsql_profile = local.cloudsql_profiles[var.cloudsql_profile]
  gar_cleanup_policies = {
    delete-untagged = {
      action = "DELETE"
      condition = {
        tag_state  = "UNTAGGED"
        older_than = var.gar_untagged_retention
      }
    }
    delete-old-sha = {
      action = "DELETE"
      condition = {
        tag_state    = "TAGGED"
        tag_prefixes = ["sha-"]
        older_than   = var.gar_sha_tagged_retention
      }
    }
    keep-recent-sha = {
      action = "KEEP"
      most_recent_versions = {
        keep_count = var.gar_sha_keep_count
      }
    }
  }
  gar_repositories = {
    apps = {
      description          = "Application images for ${var.environment}."
      image_names          = toset(["backend-api"])
      ci_push_members      = lookup(var.gar_ci_push_members, "apps", toset([]))
      runtime_pull_members = toset([local.api_service_account])
      cleanup_policies     = local.gar_cleanup_policies
    }
    workers = {
      description          = "Worker images for ${var.environment}."
      image_names          = toset(["backend-worker", "platform-ai-workers"])
      ci_push_members      = lookup(var.gar_ci_push_members, "workers", toset([]))
      runtime_pull_members = var.gar_worker_runtime_pull_members
      cleanup_policies     = local.gar_cleanup_policies
    }
    tools = {
      description          = "Tooling images for ${var.environment}."
      image_names          = toset([])
      ci_push_members      = lookup(var.gar_ci_push_members, "tools", toset([]))
      runtime_pull_members = var.gar_tool_runtime_pull_members
      cleanup_policies     = local.gar_cleanup_policies
    }
  }
  cloudsql_socket_path = module.cloudsql.instance_socket_path == null ? "/cloudsql/${var.project_id}:${var.region}:${local.db_instance_name}" : module.cloudsql.instance_socket_path
  api_plain_env = merge(
    {
      APP_ENV          = var.environment
      LOG_LEVEL        = var.api_log_level
      HTTP_PORT        = tostring(var.api_container_port)
      DB_HOST          = local.cloudsql_socket_path
      DB_NAME          = local.db_name
      DB_USER          = var.api_database_user
      AUTH_ISSUER_URL  = var.api_auth_issuer_url
      AUTH_AUDIENCE    = var.api_auth_audience
      API_RUNTIME_PATH = "cloud_run"
    },
    module.observability_support.cloud_run_env
  )
}

module "observability_support" {
  source = "../../modules/observability_support"

  environment               = var.environment
  telemetry_profile         = var.telemetry_profile
  grafana_cloud_instance_id = var.grafana_cloud_instance_id
  direct_otlp_endpoint      = var.grafana_direct_otlp_endpoint
  collector_otlp_endpoint   = var.gke_collector_otlp_endpoint
}

module "network" {
  source = "../../modules/network"

  enabled                              = var.module_activation.network
  project_id                           = var.project_id
  region                               = var.region
  network_name                         = var.network_name
  subnet_name                          = var.subnet_name
  subnet_cidr                          = var.subnet_cidr
  private_service_access_prefix_length = var.private_service_access_prefix_length
  labels                               = local.labels
}

module "gar" {
  source = "../../modules/gar"

  enabled      = var.module_activation.gar
  project_id   = var.project_id
  region       = var.region
  labels       = local.labels
  repositories = local.gar_repositories
}

module "secrets" {
  source = "../../modules/secrets"

  enabled    = var.module_activation.secrets
  project_id = var.project_id
  labels     = local.labels
  secrets = {
    grafana_otlp_ingest_token = {
      secret_id = module.observability_support.grafana_token_secret_name
      accessors = []
      annotations = {
        owner = "platform-infra"
      }
    }
    api_db_password = {
      secret_id = local.db_password_secret_id
      accessors = []
      annotations = {
        owner = "platform-infra"
      }
    }
  }
}

module "cloudsql" {
  source = "../../modules/cloudsql"

  enabled                             = var.module_activation.cloudsql
  project_id                          = var.project_id
  region                              = var.region
  instance_name                       = local.db_instance_name
  database_name                       = local.db_name
  application_user_name               = var.api_database_user
  application_user_password           = var.api_database_password
  application_user_password_secret_id = local.db_password_secret_id
  private_network_self_link           = module.network.network_self_link
  edition                             = local.cloudsql_profile.edition
  tier                                = local.cloudsql_profile.tier
  availability_type                   = local.cloudsql_profile.availability_type
  disk_type                           = local.cloudsql_profile.disk_type
  disk_size_gb                        = local.cloudsql_profile.disk_size_gb
  disk_autoresize                     = local.cloudsql_profile.disk_autoresize
  backup_enabled                      = local.cloudsql_profile.backup_enabled
  point_in_time_recovery_enabled      = local.cloudsql_profile.point_in_time_recovery_enabled
  transaction_log_retention_days      = local.cloudsql_profile.transaction_log_retention_days
  backup_start_time                   = local.cloudsql_profile.backup_start_time
  maintenance_window                  = local.cloudsql_profile.maintenance_window
  labels                              = local.labels

  depends_on = [module.network]
}

module "cloudrun_api" {
  source = "../../modules/cloudrun_api"

  enabled            = var.module_activation.cloudrun_api
  project_id         = var.project_id
  region             = var.region
  service_name       = local.api_service_name
  service_account_id = local.api_service_account_id
  container_image    = var.api_container_image
  runtime_path       = "cloud_run"
  labels             = merge(local.labels, { service = "api" })
  plain_env          = local.api_plain_env
  secret_env = merge(
    module.observability_support.cloud_run_secret_env,
    {
      DB_PASSWORD = {
        secret  = lookup(module.secrets.secret_ids, "api_db_password", local.db_password_secret_id)
        version = "latest"
      }
    }
  )
  container_port                     = var.api_container_port
  min_instance_count                 = var.api_min_instance_count
  max_instance_count                 = var.api_max_instance_count
  max_instance_request_concurrency   = var.api_max_instance_request_concurrency
  allow_unauthenticated              = var.api_allow_unauthenticated
  cloudsql_instance_connection_names = module.cloudsql.instance_connection_name == null ? [] : [module.cloudsql.instance_connection_name]
  cloudsql_enabled                   = var.module_activation.cloudsql
}

module "gke" {
  source = "../../modules/gke"

  enabled              = var.module_activation.gke
  project_id           = var.project_id
  region               = var.region
  cluster_name         = local.gke_cluster_name
  network_self_link    = module.network.network_self_link
  subnetwork_self_link = module.network.subnetwork_self_link
  labels               = local.labels
}
