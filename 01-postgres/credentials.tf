#######################################################
# RANDOM PASSWORD: SECURE CREDENTIAL FOR POSTGRES USER
#######################################################

# Generate a strong random password to be used by the 'postgres' user
# Length is set to 24 characters for robust entropy (suitable for automation and security)
# Special characters are excluded to avoid potential issues in scripts or shell escaping
resource "random_password" "postgres" {
  length  = 24    # Generate a 24-character password
  special = false # Exclude special characters (ensures compatibility across provisioning tools)
}

#####################################################
# SECRET MANAGER: STORE POSTGRES CREDENTIALS SECURELY
#####################################################

# Define a new secret in Google Secret Manager to securely store Postgres credentials
# The secret will be replicated automatically across regions (Google handles availability)
resource "google_secret_manager_secret" "postgres_secret" {
  secret_id = "postgres-credentials" # Logical name of the secret in GCP

  replication {
    auto {} # Use Google's default replication policy (global availability)
  }
}
# Create a new version of the previously defined secret
# The secret data is a JSON object containing the hardcoded username and the dynamically generated password
# This allows systems like Postgres to programmatically retrieve and use secure credentials
resource "google_secret_manager_secret_version" "postgres_secret_version" {
  secret = google_secret_manager_secret.postgres_secret.id # Reference the parent secret
  secret_data = jsonencode({                               # Encode the credentials as a JSON blob
    username = "postgres"                                  # Static username for automation
    password = random_password.postgres.result             # Inject the previously generated secure password
  })
}
