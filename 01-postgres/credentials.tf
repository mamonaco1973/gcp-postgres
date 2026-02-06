# ===============================================================================
# FILE: credentials.tf
# ===============================================================================
# Generates database credentials and stores them securely in Google Secret Manager.
#
# This module:
#   - Generates a strong random password for the Postgres database user
#   - Creates a Secret Manager secret to hold the credentials
#   - Stores the username and password as a JSON secret version
#
# NOTES:
#   - Credentials are never hardcoded in Terraform configuration
#   - Secrets are retrieved securely at runtime via IAM-controlled access
# ===============================================================================


# ===============================================================================
# GENERATE RANDOM PASSWORD FOR POSTGRES USER
# ===============================================================================
# - Generates a 24-character alphanumeric password
# - Special characters are disabled for shell and tooling compatibility
# - Used exclusively for secure service authentication
# ===============================================================================
resource "random_password" "postgres" {
  length  = 24    # Strong entropy: 24-character password
  special = false # Avoid special characters to prevent scripting issues
}


# ===============================================================================
# CREATE SECRET IN GOOGLE SECRET MANAGER
# ===============================================================================
# - Creates a managed secret to store Postgres credentials
# - Prevents hardcoding credentials in Terraform or source control
# - Uses Google-managed replication for durability and availability
# ===============================================================================
resource "google_secret_manager_secret" "postgres_secret" {
  secret_id = "postgres-credentials" # Logical identifier for the secret

  replication {
    auto {} # Default Google-managed replication policy
  }
}


# ===============================================================================
# ADD SECRET VERSION WITH CREDENTIAL DATA
# ===============================================================================
# - Writes the actual secret payload to Secret Manager
# - Stores credentials as a structured JSON object
# - Consumable by service accounts, VMs, or workloads at runtime
# ===============================================================================
resource "google_secret_manager_secret_version" "postgres_secret_version" {
  secret = google_secret_manager_secret.postgres_secret.id

  secret_data = jsonencode({
    username = "postgres" # Static database username
    password = random_password.postgres.result
  })
}
