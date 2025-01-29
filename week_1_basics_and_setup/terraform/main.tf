terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}


resource "google_storage_bucket" "demo-bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
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

resource "google_bigquery_dataset" "demo_resource_dataset" {
  dataset_id                 = var.bq_dataset_name
  friendly_name              = "friendly_name_goes_here"
  description                = "This is a test description"
  location                   = var.location
  delete_contents_on_destroy = var.delete_contents_on_destroy
  is_case_insensitive        = var.is_case_insensitive
}
