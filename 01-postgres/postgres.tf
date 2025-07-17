# =================================================================================
# CLOUD SQL INSTANCE: POSTGRESQL FLEXIBLE INSTANCE
# - Creates a managed PostgreSQL 15 database in Google Cloud SQL
# - Uses private networking only — no public IP access
# - Includes backup and maintenance policies
# =================================================================================
resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance" # Name of the Cloud SQL instance
  database_version = "POSTGRES_15"       # PostgreSQL engine version
  region           = "us-central1"       # Region for compute + networking consistency

  settings {
    tier = "db-f1-micro" # Cost-effective tier for testing/small workloads

    ip_configuration {
      ipv4_enabled    = false                                         # Disable public IP (security best practice)
      private_network = google_compute_network.postgres_vpc.self_link # Attach to custom VPC for private IP access
    }

    backup_configuration {
      enabled = true # Enable automated backups for durability
    }

    maintenance_window {
      day          = 7        # Sunday (0=Monday, 6=Saturday, 7=Sunday)
      hour         = 3        # 3 AM UTC (minimizes impact)
      update_track = "stable" # Use stable updates (avoid breaking changes)
    }
  }

  deletion_protection = false # Allow deletion (set to true in production to prevent accidents)

  depends_on = [null_resource.wait_for_vpc_peering] # Wait for private service connection before provisioning
}

# =================================================================================
# CLOUD SQL USER: POSTGRES
# - Creates a SQL-level user named "postgres"
# - Uses a strong, generated password from random_password.postgres
# =================================================================================
resource "google_sql_user" "postgres_user" {
  name     = "postgres" # Username (matches default Postgres superuser)
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres.result # Secure, randomly generated password
}

# =================================================================================
# PRIVATE DNS ZONE (Cloud DNS)
# - Creates a private zone for internal resolution of the database IP
# - Prevents hardcoding private IPs across systems
# - Enables friendly, consistent naming inside the VPC
# =================================================================================
resource "google_dns_managed_zone" "private_dns" {
  name       = "internal-db-zone"        # Internal Terraform name
  dns_name   = "internal.db-zone.local." # DNS suffix for records (MUST end in dot)
  visibility = "private"                 # Private zone — only visible inside VPC

  private_visibility_config {
    networks {
      network_url = google_compute_network.postgres_vpc.id # Scope zone visibility to the custom VPC
    }
  }

  description = "Private DNS zone for internal PostgreSQL database"
}

# =================================================================================
# PRIVATE DNS RECORD: postgres.internal.db-zone.local
# - Resolves friendly DNS name to the private IP of the database
# - Allows clients to use hostname instead of hardcoding IPs
# =================================================================================
resource "google_dns_record_set" "postgres_dns" {
  name         = "postgres.internal.db-zone.local." # Full DNS name (MUST end in dot)
  type         = "A"                                # A record (maps name to IP)
  ttl          = 300                                # Time-to-live (seconds) — 5 minutes
  managed_zone = google_dns_managed_zone.private_dns.name

  rrdatas = [google_sql_database_instance.postgres.private_ip_address] # Private IP of the DB instance
}

# =================================================================================
# WAIT RESOURCE: DELAY TO ALLOW VPC PEERING PROPAGATION
# - Ensures VPC peering connection is fully ready before Cloud SQL creation
# - Avoids race condition where Cloud SQL cannot attach to network
# =================================================================================
resource "null_resource" "wait_for_vpc_peering" {
  depends_on = [google_service_networking_connection.private_vpc_connection] # Wait for network connection

  provisioner "local-exec" {
    command = "echo 'NOTE: Waiting for VPC peering to fully propagate...' && sleep 120" # Delay to allow DNS + networking to catch up
  }
}
