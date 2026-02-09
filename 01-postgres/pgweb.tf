# ===============================================================================
# FILE: pgweb.tf
# ===============================================================================
# Deploys a lightweight VM for PostgreSQL administration using pgweb.
#
# This module:
#   - Provisions an Ubuntu 24.04 VM in the PostgreSQL VPC
#   - Assigns a public IP for browser access and SSH administration
#   - Injects database connection details via a startup script template
#   - Applies firewall tags to allow HTTP and SSH access
#   - Attaches a service account for controlled API access
#
# NOTES:
#   - This VM is publicly reachable; restrict firewall source ranges in production
#   - cloud-platform scope is broad and intended for simplicity
# ===============================================================================


# ===============================================================================
# COMPUTE INSTANCE: PGWEB VM (UBUNTU 24.04)
# ===============================================================================
# - Hosts pgweb or similar PostgreSQL admin tooling
# - Startup script configures connectivity to the private Cloud SQL instance
# ===============================================================================
resource "google_compute_instance" "pgweb_vm" {
  name         = "pgweb-vm"      # Name of the VM instance
  machine_type = "e2-small"      # Cost-effective instance type for admin workloads
  zone         = "us-central1-a" # Zone must align with subnet region


  # =============================================================================
  # BOOT DISK CONFIGURATION
  # =============================================================================
  # - Boots from the latest Ubuntu 24.04 LTS image
  # - Image is resolved dynamically via a data source
  # =============================================================================
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_latest.self_link
    }
  }


  # =============================================================================
  # NETWORK INTERFACE CONFIGURATION
  # =============================================================================
  # - Attaches instance to the custom PostgreSQL VPC and subnet
  # - access_config enables an external IP for public connectivity
  # =============================================================================
  network_interface {
    network    = google_compute_network.postgres_vpc.id
    subnetwork = google_compute_subnetwork.postgres_subnet.id
    access_config {}
  }


  # =============================================================================
  # STARTUP SCRIPT INJECTION
  # =============================================================================
  # - Renders a local pgweb startup script template
  # - Injects PostgreSQL credentials and endpoint at boot time
  # =============================================================================
  metadata_startup_script = templatefile("./scripts/pgweb.sh.template", {
    PGPASSWORD = random_password.postgres.result
    PGENDPOINT = "postgres.internal.db-zone.local"
  })


  # =============================================================================
  # FIREWALL TAGS
  # =============================================================================
  # - Tags must match firewall rule target_tags to allow SSH and HTTP
  # =============================================================================
  tags = [
    "postgres-allow-ssh",
    "postgres-allow-http"
  ]


  # =============================================================================
  # SERVICE ACCOUNT CONFIGURATION
  # =============================================================================
  # - Attaches a service account identity for Google API access
  # - Uses the client_email parsed from credentials.json
  # =============================================================================
  service_account {
    email  = local.credentials.client_email
    scopes = ["cloud-platform"]
  }


  # =============================================================================
  # DEPENDENCY MANAGEMENT
  # =============================================================================
  # - Ensures the PostgreSQL Cloud SQL instance exists before VM startup
  # - Prevents startup script failures due to missing database endpoint
  # =============================================================================
  depends_on = [
    google_sql_database_instance.postgres
  ]
}


# ===============================================================================
# DATA SOURCE: UBUNTU 24.04 LTS IMAGE
# ===============================================================================
# - Resolves the latest Ubuntu 24.04 LTS image from the official project
# - Using the family ensures security patches are picked up automatically
# ===============================================================================
data "google_compute_image" "ubuntu_latest" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}
