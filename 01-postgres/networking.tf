# ===============================================================================
# FILE: networking.tf
# ===============================================================================
# Creates the private network foundation for PostgreSQL resources.
#
# This module:
#   - Creates a custom VPC with explicit subnet planning
#   - Creates a regional subnet for compute and supporting services
#   - Adds firewall rules for HTTP and SSH access
#   - Reserves an internal IP range for Private Service Access
#   - Establishes Service Networking peering for Cloud SQL private IP
#
# NOTES:
#   - Firewall rules using 0.0.0.0/0 are not production safe
#   - Tighten source ranges and scope access using tags where possible
# ===============================================================================


# ===============================================================================
# CREATE CUSTOM VPC NETWORK
# ===============================================================================
# - Defines an isolated network environment for PostgreSQL resources
# - Disables automatic subnet creation to enforce custom IP address planning
# ===============================================================================
resource "google_compute_network" "postgres_vpc" {
  name                    = "postgres-vpc" # Name of the custom VPC
  auto_create_subnetworks = false          # Disable default subnet creation to retain control
}


# ===============================================================================
# CREATE CUSTOM SUBNET
# ===============================================================================
# - Defines a specific IP CIDR block inside the custom VPC
# - Hosts compute resources and supporting services (e.g., pgweb VM)
# ===============================================================================
resource "google_compute_subnetwork" "postgres_subnet" {
  name          = "postgres-subnet"                      # Subnet name
  ip_cidr_range = "10.0.0.0/24"                          # 256 IPs in this block
  region        = "us-central1"                          # Region must match instance placement
  network       = google_compute_network.postgres_vpc.id # Attach to the custom VPC above
}


# ===============================================================================
# FIREWALL RULE: ALLOW INBOUND HTTP (PORT 80)
# ===============================================================================
# - Enables external access to web-based tooling (e.g., pgweb UI)
# - Applies across VM instances inside the VPC
# ===============================================================================
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"                           # Rule name
  network = google_compute_network.postgres_vpc.id # Attach to VPC

  allow {
    protocol = "tcp"  # Transmission protocol
    ports    = ["80"] # Allow HTTP
  }

  source_ranges = ["0.0.0.0/0"] # Allow from all IPs (tighten for production)
}


# ===============================================================================
# FIREWALL RULE: ALLOW INBOUND SSH (PORT 22)
# ===============================================================================
# - Enables remote admin access to VMs via SSH
# - Uses tags to scope the rule to instances that require SSH access
# ===============================================================================
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"                            # Rule name
  network = google_compute_network.postgres_vpc.id # Attach to VPC

  allow {
    protocol = "tcp"  # Transmission protocol
    ports    = ["22"] # SSH port
  }

  source_ranges = ["0.0.0.0/0"] # Open access (restrict to admin IPs for production)
  target_tags   = ["allow-ssh"] # Scope to VMs that require SSH access
}


# ===============================================================================
# GLOBAL INTERNAL IP ALLOCATION FOR PRIVATE SERVICE ACCESS
# ===============================================================================
# - Reserves an internal IP range for Service Networking (Private Service Access)
# - Required for Cloud SQL private IP via VPC peering to Google managed services
# ===============================================================================
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"                     # Unique name for the IP range
  purpose       = "VPC_PEERING"                          # Must be VPC_PEERING for Service Networking
  address_type  = "INTERNAL"                             # Internal IP block, not external
  prefix_length = 16                                     # /16 = 65536 IPs (adjust to fit use)
  network       = google_compute_network.postgres_vpc.id # Attach to our custom VPC
}


# ===============================================================================
# VPC PEERING CONNECTION FOR GOOGLE MANAGED SERVICES
# ===============================================================================
# - Establishes Service Networking peering to enable managed services private IPs
# - Required service: servicenetworking.googleapis.com
#
# NOTE:
#   - Uses google-beta provider due to a known provider issue/workaround
# ===============================================================================
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.postgres_vpc.id                # Custom VPC
  service                 = "servicenetworking.googleapis.com"                    # Required GCP service
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name] # Use created IP range

  # See https://github.com/hashicorp/terraform-provider-google/issues/16275
  provider = google-beta
}
