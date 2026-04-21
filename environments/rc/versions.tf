terraform {
  required_version = "=1.14.5"

  backend "gcs" {
    bucket = "mpa-forge-bp-tfstate-rc"
    prefix = "rc/platform-infra"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
