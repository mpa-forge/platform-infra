locals {
  labels = {
    env        = var.environment
    project    = "platform-blueprint"
    service    = "platform-infra"
    managed_by = "terraform"
    region     = var.region
  }

  gar_repositories = {
    apps = {
      description          = "Application images for ${var.environment}."
      ci_push_members      = []
      runtime_pull_members = []
    }
    workers = {
      description          = "Worker images for ${var.environment}."
      ci_push_members      = []
      runtime_pull_members = []
    }
    tools = {
      description          = "Tooling images for ${var.environment}."
      ci_push_members      = []
      runtime_pull_members = []
    }
  }

  api_service_name       = "api-${var.environment}"
  api_service_account_id = "api-${var.environment}-sa"
  db_instance_name       = "platform-${var.environment}-db"
  db_name                = "platform_${var.environment}"
  gke_cluster_name       = "platform-${var.environment}"
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
  }
}

module "cloudsql" {
  source = "../../modules/cloudsql"

  enabled                   = var.module_activation.cloudsql
  project_id                = var.project_id
  region                    = var.region
  instance_name             = local.db_instance_name
  database_name             = local.db_name
  private_network_self_link = module.network.network_self_link
  labels                    = local.labels

  depends_on = [module.network]
}

module "cloudrun_api" {
  source = "../../modules/cloudrun_api"

  enabled                            = var.module_activation.cloudrun_api
  project_id                         = var.project_id
  region                             = var.region
  service_name                       = local.api_service_name
  service_account_id                 = local.api_service_account_id
  container_image                    = var.api_container_image
  labels                             = merge(local.labels, { service = "api" })
  plain_env                          = module.observability_support.cloud_run_env
  secret_env                         = module.observability_support.cloud_run_secret_env
  cloudsql_instance_connection_names = module.cloudsql.instance_connection_name == null ? [] : [module.cloudsql.instance_connection_name]
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
