terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  credentials = file("/workspaces/2025_data_engineering_zoomcamp/week_1_basics_and_setup/terraform/keys/my_creds.json")
  project     = "de-zoomcamp-terraform-449109"
  region      = "us-central1"
}


resource "google_storage_bucket" "demo-bucket-" {
  name          = "de-zoomcamp-terraform-449109-terra-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
