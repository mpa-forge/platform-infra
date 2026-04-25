locals {
  labels = {
    env        = var.environment
    project    = "platform-blueprint"
    service    = "platform-infra"
    managed_by = "terraform"
    region     = var.region
  }

  preset_catalog = {
    "single-vps" = {
      frontend_runtime = "vps"
      backend_runtime  = "vps"
      database_runtime = "vps"
      observability    = "vps-manual"
      module_activation = {
        network      = true
        gar          = false
        cloudsql     = false
        secrets      = false
        cloudrun_api = false
        gke          = false
        vps_stack    = true
      }
    }
    "cloudrun-cloudsql" = {
      frontend_runtime = "external"
      backend_runtime  = "cloud_run"
      database_runtime = "cloudsql"
      observability    = "grafana-direct-otlp"
      module_activation = {
        network      = true
        gar          = true
        cloudsql     = true
        secrets      = true
        cloudrun_api = true
        gke          = false
        vps_stack    = false
      }
    }
    "cloudrun-cdn-cloudsql" = {
      frontend_runtime = "cdn"
      backend_runtime  = "cloud_run"
      database_runtime = "cloudsql"
      observability    = "grafana-direct-otlp"
      module_activation = {
        network      = true
        gar          = true
        cloudsql     = true
        secrets      = true
        cloudrun_api = true
        gke          = false
        vps_stack    = false
      }
    }
    "gke-cloudsql" = {
      frontend_runtime = "cdn"
      backend_runtime  = "gke"
      database_runtime = "cloudsql"
      observability    = "gke-collector"
      module_activation = {
        network      = true
        gar          = true
        cloudsql     = true
        secrets      = true
        cloudrun_api = false
        gke          = true
        vps_stack    = false
      }
    }
  }

  stack_config = local.preset_catalog[var.deployment_preset]
  module_activation = {
    for module_name, enabled in local.stack_config.module_activation :
    module_name => var.deployment_enabled && enabled
  }

  api_service_name       = "api-${var.environment}"
  api_service_account_id = "api-${var.environment}-sa"
  api_service_account    = "serviceAccount:${local.api_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
  db_instance_name       = "platform-${var.environment}-db"
  db_name                = "platform_${var.environment}"
  db_password_secret_id  = "api-db-password-${var.environment}"
  gke_cluster_name       = "platform-${var.environment}"
  vps_instance_name      = "stack-${var.environment}"
  vps_service_account_id = "stack-${var.environment}-sa"
  api_runtime_path = (
    local.stack_config.backend_runtime == "cloud_run" ? "cloud_run" :
    local.stack_config.backend_runtime == "gke" ? "gke" :
    "vps"
  )

  gke_secret_sync_service_accounts = {
    external_secrets = {
      account_id                 = "eso-${var.environment}-sa"
      kubernetes_namespace       = var.gke_external_secrets_namespace
      kubernetes_service_account = var.gke_external_secrets_service_account_name
    }
    backend_api = {
      account_id                 = "api-${var.environment}-gke-sa"
      kubernetes_namespace       = var.gke_api_namespace
      kubernetes_service_account = var.gke_api_service_account_name
    }
  }

  ai_worker_lanes = {
    for lane_name, lane in var.ai_worker_lanes :
    lane_name => {
      target_repo          = lane.target_repo
      service_account_id   = coalesce(try(lane.service_account_id, null), "aiw-${replace(lane_name, "_", "-")}-${var.environment}-sa")
      github_pat_secret_id = coalesce(try(lane.github_pat_secret_id, null), "ai-worker-github-pat-${replace(lane_name, "_", "-")}-${var.environment}")
      agent_key_enabled    = try(lane.agent_key_enabled, false)
      agent_key_secret_id  = coalesce(try(lane.agent_key_secret_id, null), "ai-worker-agent-key-${replace(lane_name, "_", "-")}-${var.environment}")
    }
  }

  ai_worker_runtime_pull_members = toset([
    for lane in values(local.ai_worker_lanes) :
    "serviceAccount:${lane.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
  ])

  api_secret_delivery = join(",", compact([
    local.stack_config.backend_runtime == "cloud_run" ? "cloud-run-direct" : null,
    local.module_activation.gke ? "gke-eso" : null,
    local.stack_config.backend_runtime == "vps" ? "manual-vps" : null,
  ]))

  runtime_secret_catalog = merge(
    {
      grafana_otlp_ingest_token = {
        secret_id         = module.observability_support.grafana_token_secret_name
        cloud_run_env_var = local.stack_config.backend_runtime == "cloud_run" ? "GRAFANA_OTLP_INGEST_TOKEN" : null
        accessors = local.module_activation.gke ? [
          "serviceAccount:${local.gke_secret_sync_service_accounts.external_secrets.account_id}@${var.project_id}.iam.gserviceaccount.com",
          "serviceAccount:${local.gke_secret_sync_service_accounts.backend_api.account_id}@${var.project_id}.iam.gserviceaccount.com",
        ] : []
        eso_enabled            = local.module_activation.gke
        eso_target_secret_name = "backend-api-runtime-secrets"
        eso_target_secret_key  = "GRAFANA_OTLP_INGEST_TOKEN"
        annotations = {
          owner       = "platform-infra"
          consumer    = "backend-api"
          delivery    = local.api_secret_delivery
          phase_owner = "deployment-presets"
        }
      }
      api_db_password = {
        secret_id         = local.db_password_secret_id
        cloud_run_env_var = local.stack_config.backend_runtime == "cloud_run" ? "DB_PASSWORD" : null
        accessors = local.module_activation.gke ? [
          "serviceAccount:${local.gke_secret_sync_service_accounts.external_secrets.account_id}@${var.project_id}.iam.gserviceaccount.com",
          "serviceAccount:${local.gke_secret_sync_service_accounts.backend_api.account_id}@${var.project_id}.iam.gserviceaccount.com",
        ] : []
        eso_enabled            = local.module_activation.gke
        eso_target_secret_name = "backend-api-runtime-secrets"
        eso_target_secret_key  = "DB_PASSWORD"
        annotations = {
          owner       = "platform-infra"
          consumer    = "backend-api"
          delivery    = local.api_secret_delivery
          phase_owner = "deployment-presets"
        }
      }
    },
    {
      for lane_name, lane in local.ai_worker_lanes :
      "ai_worker_${lane_name}_github_pat" => {
        secret_id         = lane.github_pat_secret_id
        cloud_run_env_var = "GITHUB_TOKEN"
        accessors = [
          "serviceAccount:${lane.service_account_id}@${var.project_id}.iam.gserviceaccount.com",
        ]
        eso_enabled = false
        annotations = {
          owner       = "platform-infra"
          consumer    = "platform-ai-workers"
          worker_lane = lane_name
          target_repo = lane.target_repo
          env_var     = "GITHUB_TOKEN"
          delivery    = "cloud-run-direct"
          phase_owner = "p5-t07"
        }
      }
    },
    {
      for lane_name, lane in local.ai_worker_lanes :
      "ai_worker_${lane_name}_agent_key" => {
        secret_id         = lane.agent_key_secret_id
        cloud_run_env_var = "OPENAI_API_KEY"
        accessors = [
          "serviceAccount:${lane.service_account_id}@${var.project_id}.iam.gserviceaccount.com",
        ]
        eso_enabled = false
        annotations = {
          owner       = "platform-infra"
          consumer    = "platform-ai-workers"
          worker_lane = lane_name
          target_repo = lane.target_repo
          env_var     = "OPENAI_API_KEY"
          delivery    = "cloud-run-direct"
          optional    = "true"
          phase_owner = "p5-t07"
        }
      }
      if lane.agent_key_enabled
    }
  )

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
      runtime_pull_members = local.stack_config.backend_runtime == "cloud_run" ? toset([local.api_service_account]) : toset([])
      cleanup_policies     = local.gar_cleanup_policies
    }
    workers = {
      description          = "Worker images for ${var.environment}."
      image_names          = toset(["backend-worker", "platform-ai-workers"])
      ci_push_members      = lookup(var.gar_ci_push_members, "workers", toset([]))
      runtime_pull_members = setunion(var.gar_worker_runtime_pull_members, local.ai_worker_runtime_pull_members)
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
      DB_HOST          = local.stack_config.database_runtime == "cloudsql" ? local.cloudsql_socket_path : "127.0.0.1"
      DB_NAME          = local.db_name
      DB_USER          = var.api_database_user
      AUTH_ISSUER_URL  = var.api_auth_issuer_url
      AUTH_AUDIENCE    = var.api_auth_audience
      API_RUNTIME_PATH = local.api_runtime_path
    },
    module.observability_support.cloud_run_env
  )

  vps_metadata = merge(
    {
      PLATFORM_ENV      = var.environment
      DEPLOYMENT_PRESET = var.deployment_preset
      FRONTEND_PORT     = tostring(var.vps_frontend_port)
      BACKEND_PORT      = tostring(var.vps_backend_port)
      DATABASE_PORT     = tostring(var.vps_database_port)
      DATABASE_NAME     = local.db_name
      DATABASE_USER     = var.api_database_user
      API_RUNTIME_PATH  = local.api_runtime_path
    },
    var.frontend_public_url == null ? {} : { FRONTEND_PUBLIC_URL = var.frontend_public_url }
  )

  vps_frontend_url = try(module.vps_stack.frontend_url, null)
  vps_backend_url  = try(module.vps_stack.backend_url, null)
  gke_backend_workload_identity_principal = try(
    module.gke.workload_identity_principals["backend_api"],
    null
  )
  frontend_public_url = (
    local.stack_config.frontend_runtime == "vps" ? local.vps_frontend_url : var.frontend_public_url
  )
  backend_service_url = (
    local.stack_config.backend_runtime == "cloud_run" ? module.cloudrun_api.service_uri :
    local.stack_config.backend_runtime == "vps" ? local.vps_backend_url :
    null
  )
  backend_service_account_email = (
    local.stack_config.backend_runtime == "cloud_run" ? module.cloudrun_api.service_account_email :
    local.stack_config.backend_runtime == "vps" ? module.vps_stack.service_account_email :
    try(local.gke_backend_workload_identity_principal.google_service_account_email, null)
  )
  backend_runtime_contract_base = {
    runtime_path                       = local.api_runtime_path
    ingress                            = null
    allow_unauthenticated              = null
    container_port                     = null
    cloudsql_enabled                   = null
    cloudsql_instance_connection_names = []
    cloudsql_mount_path                = null
    plain_env_names                    = []
    secret_env_names                   = []
    runtime_secret_access_env_names    = []
    runtime_secret_access_secret_ids   = []
    startup_probe_path                 = null
    service_uri                        = null
    zone                               = null
    machine_type                       = null
    public_ip                          = null
    frontend_url                       = null
    backend_url                        = null
    database_host                      = null
    database_port                      = null
    startup_script_configured          = null
    cluster_name                       = null
    cluster_endpoint                   = null
    workload_identity_principal        = null
    eso_secret_mappings                = {}
  }
  backend_runtime_contracts = {
    cloud_run = merge(
      local.backend_runtime_contract_base,
      module.cloudrun_api.runtime_contract
    )
    vps = merge(
      local.backend_runtime_contract_base,
      module.vps_stack.runtime_contract
    )
    gke = merge(
      local.backend_runtime_contract_base,
      {
        cluster_name                = module.gke.cluster_name
        cluster_endpoint            = module.gke.cluster_endpoint
        workload_identity_principal = local.gke_backend_workload_identity_principal
        eso_secret_mappings         = module.gke.eso_secret_mappings
      }
    )
  }
  backend_runtime_contract = local.backend_runtime_contracts[local.stack_config.backend_runtime]

  frontend_contract = {
    runtime_kind = local.stack_config.frontend_runtime
    public_url   = local.frontend_public_url
    endpoint     = local.frontend_public_url
    managed      = local.stack_config.frontend_runtime != "external"
  }

  backend_contract = {
    runtime_kind          = local.stack_config.backend_runtime
    service_name          = local.stack_config.backend_runtime == "cloud_run" ? module.cloudrun_api.service_name : local.stack_config.backend_runtime == "vps" ? module.vps_stack.instance_name : module.gke.cluster_name
    service_url           = local.backend_service_url
    service_account_email = local.backend_service_account_email
    runtime_contract      = local.backend_runtime_contract
  }

  database_contract = {
    runtime_kind              = local.stack_config.database_runtime
    host                      = local.stack_config.database_runtime == "cloudsql" ? local.cloudsql_socket_path : module.vps_stack.database_host
    port                      = local.stack_config.database_runtime == "cloudsql" ? null : module.vps_stack.database_port
    connection_name           = module.cloudsql.instance_connection_name
    connection_strategy       = local.stack_config.database_runtime == "cloudsql" ? "cloudsql-socket" : "localhost-tcp"
    profile                   = local.stack_config.database_runtime == "cloudsql" ? var.cloudsql_profile : "single-vps"
    edition                   = module.cloudsql.edition
    tier                      = module.cloudsql.tier
    database_name             = local.stack_config.database_runtime == "cloudsql" ? module.cloudsql.database_name : local.db_name
    database_user             = local.stack_config.database_runtime == "cloudsql" ? coalesce(module.cloudsql.application_user_name, var.api_database_user) : var.api_database_user
    password_secret_name      = local.stack_config.database_runtime == "cloudsql" ? lookup(module.secrets.secret_ids, "api_db_password", local.db_password_secret_id) : null
    runtime_secret_catalog_id = lookup(module.secrets.secret_ids, "api_db_password", local.db_password_secret_id)
  }

  operational_contract = {
    active_preset      = var.deployment_preset
    deployment_enabled = var.deployment_enabled
    module_activation  = local.module_activation
    image_uri_prefixes = module.gar.image_uri_prefixes
    artifact_registry = {
      repositories = module.gar.repository_ids
      uris         = module.gar.repository_uris
    }
    observability_mode = local.stack_config.observability
    runtime_baseline   = "cloud_run"
    backend_runtime    = local.stack_config.backend_runtime
  }

  deployment_contract = {
    active_preset        = var.deployment_preset
    deployment_enabled   = var.deployment_enabled
    frontend_contract    = local.frontend_contract
    backend_contract     = local.backend_contract
    database_contract    = local.database_contract
    operational_contract = local.operational_contract
  }

  service_contracts = {
    active_preset             = var.deployment_preset
    deployment_enabled        = var.deployment_enabled
    frontend_contract         = local.frontend_contract
    backend_contract          = local.backend_contract
    database_contract         = local.database_contract
    operational_contract      = local.operational_contract
    api_service_name          = local.backend_contract.service_name
    api_service_uri           = local.backend_contract.service_url
    api_service_account_email = local.backend_contract.service_account_email
    api_runtime_contract      = local.backend_runtime_contract
    runtime_secret_catalog    = module.secrets.secret_catalog
    gke_secret_sync_contract = {
      cluster_secret_store_name    = var.gke_cluster_secret_store_name
      workload_identity_principals = module.gke.workload_identity_principals
      backend_api_secret_mappings  = module.gke.eso_secret_mappings
    }
    ai_worker_runtime_contracts = {
      for lane_name, lane in local.ai_worker_lanes :
      lane_name => {
        target_repo           = lane.target_repo
        service_account_email = try(google_service_account.ai_worker_runtime[lane_name].email, null)
        image_repository      = "workers"
        runtime_mode          = "cloud"
        secret_env = merge(
          {
            GITHUB_TOKEN = lookup(module.secrets.secret_ids, "ai_worker_${lane_name}_github_pat", lane.github_pat_secret_id)
          },
          lane.agent_key_enabled ? {
            OPENAI_API_KEY = lookup(module.secrets.secret_ids, "ai_worker_${lane_name}_agent_key", lane.agent_key_secret_id)
          } : {}
        )
      }
    }
    grafana_token_secret_name = module.observability_support.grafana_token_secret_name
    cloudsql_connection_name  = module.cloudsql.instance_connection_name
    api_database_contract     = local.database_contract
    artifact_registry_repos   = module.gar.repository_ids
    artifact_registry_uris    = module.gar.repository_uris
    image_uri_prefixes        = module.gar.image_uri_prefixes
  }
}

resource "google_service_account" "ai_worker_runtime" {
  for_each = var.deployment_enabled ? local.ai_worker_lanes : {}

  project      = var.project_id
  account_id   = each.value.service_account_id
  display_name = "AI worker runtime (${each.key})"
  description  = "Runtime identity for the ${each.key} AI worker lane."
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

  enabled                              = local.module_activation.network
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

  enabled      = local.module_activation.gar
  project_id   = var.project_id
  region       = var.region
  labels       = local.labels
  repositories = local.gar_repositories
}

module "secrets" {
  source = "../../modules/secrets"

  enabled      = local.module_activation.secrets
  project_id   = var.project_id
  environment  = var.environment
  catalog_name = "runtime-secret-delivery"
  labels       = local.labels
  secrets      = local.runtime_secret_catalog
}

module "cloudsql" {
  source = "../../modules/cloudsql"

  enabled                             = local.module_activation.cloudsql
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

  enabled            = local.module_activation.cloudrun_api
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
  runtime_secret_access_env_names  = toset(["DB_PASSWORD", "GRAFANA_OTLP_INGEST_TOKEN"])
  container_port                   = var.api_container_port
  min_instance_count               = var.api_min_instance_count
  max_instance_count               = var.api_max_instance_count
  max_instance_request_concurrency = var.api_max_instance_request_concurrency
  allow_unauthenticated            = var.api_allow_unauthenticated
  cloudsql_instance_connection_names = (
    module.cloudsql.instance_connection_name == null ? [] : [module.cloudsql.instance_connection_name]
  )
  cloudsql_enabled = local.module_activation.cloudsql
}

module "gke" {
  source = "../../modules/gke"

  enabled              = local.module_activation.gke
  project_id           = var.project_id
  region               = var.region
  cluster_name         = local.gke_cluster_name
  network_self_link    = module.network.network_self_link
  subnetwork_self_link = module.network.subnetwork_self_link
  labels               = local.labels
  workload_identity_principals = {
    for principal_key, principal in local.gke_secret_sync_service_accounts :
    principal_key => {
      google_service_account_id  = principal.account_id
      kubernetes_namespace       = principal.kubernetes_namespace
      kubernetes_service_account = principal.kubernetes_service_account
      secret_ids = toset([
        lookup(module.secrets.secret_ids, "grafana_otlp_ingest_token", module.observability_support.grafana_token_secret_name),
        lookup(module.secrets.secret_ids, "api_db_password", local.db_password_secret_id),
      ])
      display_name = "GKE secret sync (${principal_key})"
      description  = "Workload Identity principal for ${principal.kubernetes_namespace}/${principal.kubernetes_service_account}."
    }
  }
  eso_secret_mappings = {
    grafana_otlp_ingest_token = {
      secret_id              = lookup(module.secrets.secret_ids, "grafana_otlp_ingest_token", module.observability_support.grafana_token_secret_name)
      kubernetes_namespace   = var.gke_api_namespace
      kubernetes_secret_name = "backend-api-runtime-secrets"
      kubernetes_secret_key  = "GRAFANA_OTLP_INGEST_TOKEN"
      version                = "latest"
    }
    api_db_password = {
      secret_id              = lookup(module.secrets.secret_ids, "api_db_password", local.db_password_secret_id)
      kubernetes_namespace   = var.gke_api_namespace
      kubernetes_secret_name = "backend-api-runtime-secrets"
      kubernetes_secret_key  = "DB_PASSWORD"
      version                = "latest"
    }
  }
}

module "vps_stack" {
  source = "../../modules/vps_stack"

  enabled              = local.module_activation.vps_stack
  project_id           = var.project_id
  region               = var.region
  zone                 = var.vps_zone
  instance_name        = local.vps_instance_name
  service_account_id   = local.vps_service_account_id
  network_self_link    = module.network.network_self_link
  subnetwork_self_link = module.network.subnetwork_self_link
  machine_type         = var.vps_machine_type
  boot_disk_image      = var.vps_boot_disk_image
  boot_disk_size_gb    = var.vps_boot_disk_size_gb
  public_source_ranges = var.vps_allow_public_source_ranges
  ssh_source_ranges    = var.vps_allow_ssh_source_ranges
  frontend_port        = var.vps_frontend_port
  backend_port         = var.vps_backend_port
  database_port        = var.vps_database_port
  metadata             = local.vps_metadata
  startup_script       = var.vps_startup_script
  labels               = merge(local.labels, { service = "vps" })
}
