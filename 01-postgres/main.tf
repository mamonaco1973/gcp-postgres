############################################
# GOOGLE CLOUD PROVIDER CONFIGURATION
############################################

# Configures the Google Cloud provider block for all Terraform resources
# This defines *how* Terraform talks to GCP, and with *what identity*
provider "google" {
  project     = local.credentials.project_id   # Dynamically pulls the project ID from decoded credentials (prevents hardcoding)
  credentials = file("../credentials.json")    # Loads the full path to a local GCP service account credentials file
                                               # ⚠️ Must be a properly formatted JSON file from IAM, or authentication will fail
                                               # ⚠️ Ensure this file is secured and **never** committed to source control
}

############################################
# LOCAL VARIABLES: CREDENTIALS EXTRACTION
############################################

# Parses the service account JSON file to extract reusable properties
# This avoids manually defining things like project_id or service_account_email
locals {
  credentials = jsondecode(file("../credentials.json"))  # Decodes the raw JSON file into a usable map object
                                                         # Contains fields like project_id, client_email, private_key, etc.

  service_account_email = local.credentials.client_email # Pulls out the `client_email` field (used for IAM roles, bindings, logging)
                                                         # ⚠️ Will break if JSON structure is invalid or missing this field
}
