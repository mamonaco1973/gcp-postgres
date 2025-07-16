############################################
# RANDOM PASSWORD: SECURE CREDENTIAL FOR PACKER
############################################

# Generate a strong random password to be used by the 'packer' user
# Length is set to 24 characters for robust entropy (suitable for automation and security)
# Special characters are excluded to avoid potential issues in scripts or shell escaping
resource "random_password" "generated" {
  length  = 24        # Generate a 24-character password
  special = false     # Exclude special characters (ensures compatibility across provisioning tools)
}

############################################
# SECRET MANAGER: STORE PACKER CREDENTIALS SECURELY
############################################

# Define a new secret in Google Secret Manager to securely store Packer credentials
# The secret will be replicated automatically across regions (Google handles availability)
resource "google_secret_manager_secret" "packer_secret" {
  secret_id = "packer-credentials"  # Logical name of the secret in GCP

  replication {
    auto {}                         # Use Google's default replication policy (global availability)
  }
}

# Create a new version of the previously defined secret
# The secret data is a JSON object containing the hardcoded username and the dynamically generated password
# This allows systems like Packer to programmatically retrieve and use secure credentials
resource "google_secret_manager_secret_version" "packer_secret_version" {
  secret      = google_secret_manager_secret.packer_secret.id  # Reference the parent secret
  secret_data = jsonencode({                                   # Encode the credentials as a JSON blob
    username = "packer"                                        # Static username for automation
    password = random_password.generated.result                # Inject the previously generated secure password
  })
}
