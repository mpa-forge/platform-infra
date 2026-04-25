terraform {
  required_version = "=1.14.5"

  backend "gcs" {
    bucket = "mpa-forge-bp-tfstate-prod"
    prefix = "prod/platform-infra"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}
