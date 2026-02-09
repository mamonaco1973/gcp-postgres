# ===============================================================================
# FILE: postgres.tf
# ===============================================================================
# Provisions a private PostgreSQL Cloud SQL instance and supporting resources.
#
# This module:
#   - Creates a PostgreSQL 15 Cloud SQL instance with private IP only
#   - Configures backups and a defined maintenance window
#   - Creates a SQL-level postgres user with a generated password
#   - Publishes a private DNS record for internal name resolution
#   - Enforces ordering to avoid Service Networking race conditions
#
# NOTES:
#   - Public IP access is explicitly disabled
#   - Deletion protection is disabled for non-production use
# ===============================================================================


# ===============================================================================
# CLOUD SQL INSTANCE: POSTGRESQL
# ===============================================================================
# - Managed PostgreSQL 15 database using private networking only
# - Attached to a custom VPC via Private Service Access
# - Includes backup and maintenance policies
# ===============================================================================
resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance" # Name of the Cloud SQL instance
  database_version = "POSTGRES_18"       # PostgreSQL engine version
  region           = "us-central1"       # Region for compute + networking consistency

  settings {
    tier = "db-f1-micro" # Cost-effective tier for testing and small workloads

    ip_configuration {
      ipv4_enabled    = false                                         # Disable public IP access
      private_network = google_compute_network.postgres_vpc.self_link # Attach to custom VPC
    }

    backup_configuration {
      enabled = true # Enable automated backups for durability
    }

    maintenance_window {
      day          = 7        # Sunday (0=Monday, 6=Saturday, 7=Sunday)
      hour         = 3        # 3 AM UTC to minimize impact
      update_track = "stable" # Stable update track (avoid breaking changes)
    }
  }

  deletion_protection = false # Allow deletion (enable in production)

  # Wait for Service Networking peering propagation before instance creation
  depends_on = [
    null_resource.wait_for_vpc_peering
  ]
}


# ===============================================================================
# CLOUD SQL USER: POSTGRES
# ===============================================================================
# - Creates a SQL-level postgres user
# - Uses a strong, generated password from random_password.postgres
# ===============================================================================
resource "google_sql_user" "postgres_user" {
  name     = "postgres" # Default PostgreSQL superuser name
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres.result
}


# ===============================================================================
# PRIVATE DNS ZONE: INTERNAL DATABASE RESOLUTION
# ===============================================================================
# - Creates a private Cloud DNS zone for internal database name resolution
# - Prevents hardcoding private IP addresses across clients
# ===============================================================================
resource "google_dns_managed_zone" "private_dns" {
  name       = "internal-db-zone"        # Internal Terraform name
  dns_name   = "internal.db-zone.local." # DNS suffix (must end with a dot)
  visibility = "private"                 # Zone visible only inside the VPC

  private_visibility_config {
    networks {
      network_url = google_compute_network.postgres_vpc.id
    }
  }

  description = "Private DNS zone for internal PostgreSQL database"
}


# ===============================================================================
# PRIVATE DNS RECORD: POSTGRES HOSTNAME
# ===============================================================================
# - Maps a friendly hostname to the database private IP
# - Enables clients to connect using DNS instead of hardcoded IPs
# ===============================================================================
resource "google_dns_record_set" "postgres_dns" {
  name         = "postgres.internal.db-zone.local." # Fully qualified DNS name
  type         = "A"                                # A record (name → IP)
  ttl          = 300                                # 5-minute TTL
  managed_zone = google_dns_managed_zone.private_dns.name

  rrdatas = [
    google_sql_database_instance.postgres.private_ip_address
  ]
}


# ===============================================================================
# WAIT RESOURCE: SERVICE NETWORKING PROPAGATION
# ===============================================================================
# - Forces a delay to allow Private Service Access to converge
# - Prevents intermittent Cloud SQL creation failures due to async propagation
# ===============================================================================
resource "null_resource" "wait_for_vpc_peering" {
  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  provisioner "local-exec" {
    command = "echo 'NOTE: Waiting for VPC peering to fully propagate...' && sleep 300"
  }
}
