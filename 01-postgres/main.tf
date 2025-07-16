terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>5"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>4"
    }
  }
}

# =================================================================================
# GOOGLE CLOUD PROVIDER CONFIGURATION
# - This block configures the Google Cloud provider for Terraform
# - Specifies which GCP project to use and which service account credentials to authenticate with
# - All resources created by Terraform will use this configuration
# =================================================================================
provider "google" {
  project     = local.credentials.project_id # Dynamically reference project ID from decoded credentials (avoids hardcoding)
  credentials = file("../credentials.json")  # Load credentials file (must be a valid GCP service account key in JSON format)
}

# =================================================================================
# GOOGLE-BETA CLOUD PROVIDER CONFIGURATION
# - This block configures the Google Cloud provider for Terraform
# - Specifies which GCP project to use and which service account credentials to authenticate with
# - All resources created by Terraform will use this configuration
# =================================================================================
provider "google-beta" {
  project     = local.credentials.project_id # Dynamically reference project ID from decoded credentials (avoids hardcoding)
  credentials = file("../credentials.json")  # Load credentials file (must be a valid GCP service account key in JSON format)
}


# =================================================================================
# LOCAL VARIABLES: PARSE AND EXTRACT SERVICE ACCOUNT DETAILS
# - Decodes the service account JSON file into a usable map
# - Extracts reusable fields like project_id and service_account_email
# - Simplifies usage across multiple Terraform modules and IAM bindings
# =================================================================================
locals {
  credentials = jsondecode(file("../credentials.json")) # Parse the raw JSON file and expose as local object
  # Structure includes fields such as: project_id, client_email, private_key, type, etc.

  service_account_email = local.credentials.client_email # Extracts email (used in IAM role bindings, logging, and labeling)
  # ⚠️ This field must exist in the JSON — will error if malformed or renamed
}
