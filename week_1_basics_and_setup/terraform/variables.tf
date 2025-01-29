# variable "credential" {
#   description = "My credentials"
#   default     = file("/workspaces/2025_data_engineering_zoomcamp/week_1_basics_and_setup/terraform/keys/my_creds.json")
# }

variable "credentials" {
  description = "My credentials"
  default     = "./keys/my_creds.json"
}

variable "region" {
  description = "Dataset region"
  default     = "us-central1"
}

variable "project" {
  description = "Project"
  default     = "de-zoomcamp-terraform-449109"
}

variable "location" {
  description = "Project location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "Demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My storage bucket name"
  default     = "de-zoomcamp-terraform-449109-terra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}

variable "is_case_insensitive" {
  description = "Dataset case insensitivity"
  default     = "true"
}

variable "delete_contents_on_destroy" {
  description = "Delete dataset contents (tables) when deleting the dataset. i.e.: delete dataset and its contents"
  default     = "true"
}
