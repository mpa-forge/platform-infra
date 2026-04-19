project_id          = "mpa-forge-bp-prod"
state_project_id    = "mpa-forge-bp-tfstate"
network_name        = "platform-prod"
subnet_name         = "platform-prod-us-east4"
subnet_cidr         = "10.34.0.0/24"
api_container_image = "us-east4-docker.pkg.dev/mpa-forge-bp-prod/apps/backend-api:sha-placeholder"

module_activation = {
  network      = false
  gar          = false
  cloudsql     = false
  secrets      = false
  cloudrun_api = false
  gke          = false
}
