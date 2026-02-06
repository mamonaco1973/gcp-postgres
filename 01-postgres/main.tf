# ===============================================================================
# FILE: main.tf
# ===============================================================================
# Defines Terraform provider requirements and configures Google Cloud providers.
#
# This file:
#   - Pins Google and Google Beta providers to compatible major versions
#   - Configures providers using a service account credentials file
#   - Parses credentials.json into reusable local values
#
# NOTES:
#   - credentials.json must be a valid GCP service account key file
#   - Providers are shared by all resources in this module
# ===============================================================================


# ===============================================================================
# TERRAFORM PROVIDER REQUIREMENTS
# ===============================================================================
# - Locks provider sources and major versions for repeatable builds
# - Prevents accidental upgrades that may introduce breaking changes
# ===============================================================================
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


# ===============================================================================
# GOOGLE CLOUD PROVIDER CONFIGURATION
# ===============================================================================
# - Primary Google Cloud provider
# - Authenticates using a service account JSON key file
# - Project ID is derived from decoded credentials (avoids hardcoding)
# ===============================================================================
provider "google" {
  project     = local.credentials.project_id
  credentials = file("../credentials.json")
}


# ===============================================================================
# GOOGLE BETA PROVIDER CONFIGURATION
# ===============================================================================
# - Enables access to beta / preview GCP APIs and fields
# - Required for certain networking and service networking resources
# - Uses the same project and credentials as the primary provider
# ===============================================================================
provider "google-beta" {
  project     = local.credentials.project_id
  credentials = file("../credentials.json")
}


# ===============================================================================
# LOCAL VARIABLES: PARSE SERVICE ACCOUNT CREDENTIALS
# ===============================================================================
# - Decodes credentials.json into a usable local object
# - Extracts commonly used fields for reuse across resources
# ===============================================================================
locals {
  credentials = jsondecode(file("../credentials.json"))
  # Expected fields include: project_id, client_email, private_key, type, etc.

  service_account_email = local.credentials.client_email
  # This field must exist in the JSON and will error if missing or renamed
}
