############################################
# GOOGLE CLOUD PROVIDER CONFIGURATION
############################################

# Configures the Google Cloud provider to interact with the specified project
# Uses a local credentials JSON file to authenticate Terraform operations
# Ensures that all resources are provisioned under the correct GCP project and identity
provider "google" {
  project     = local.credentials.project_id  # Pulls the project ID from the decoded credentials file (ensures dynamic, environment-specific use)
  credentials = file("../credentials.json")   # Loads raw credentials file from parent directory (assumes file exists and is properly secured)
}

############################################
# LOCAL VARIABLES: CREDENTIALS PARSING
############################################

# Decodes the service account credentials file into a usable map
# Extracts useful fields like project ID and service account email for later reference
locals {
  credentials = jsondecode(file("../credentials.json")) # Converts JSON content into a map structure (now accessible via dot notation)
  service_account_email = local.credentials.client_email # Explicitly extracts the service account's email (can be used for IAM bindings or audit logs)
}

############################################
# DATA SOURCES: EXISTING NETWORK INFRASTRUCTURE
############################################

# Lookup existing VPC by name from the current project
data "google_compute_network" "packer_vpc" {
  name = var.vpc_name  # Dynamically pull the VPC name from input variable
}

# Lookup existing subnet by name and region
data "google_compute_subnetwork" "packer_subnet" {
  name   = var.subnet_name   # Dynamically pull subnet name from input variable
  region = "us-central1"     # Region must match the one where subnet is deployed
}