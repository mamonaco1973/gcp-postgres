############################################
# CUSTOM VPC: DEFINES ISOLATED NETWORK
############################################
resource "google_compute_network" "postgres_vpc" {
  name                    = "postgres-vpc" # Name for the custom VPC
  auto_create_subnetworks = false          # Disables auto-created subnets so we can define explicit subnet structure
}

############################################
# CUSTOM SUBNET: DEFINES INTERNAL IP RANGE
############################################
resource "google_compute_subnetwork" "postgres_subnet" {
  name          = "postgres-subnet"                      # Name for the custom subnet
  ip_cidr_range = "10.0.0.0/24"                          # Internal IP range (256 IPs total)
  region        = "us-central1"                          # Region where the subnet will be created
  network       = google_compute_network.postgres_vpc.id # Connects this subnet to the custom VPC
}

############################################
# FIREWALL RULE: ALLOW INBOUND HTTP TRAFFIC
############################################
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"                           # Name for the HTTP firewall rule
  network = google_compute_network.postgres_vpc.id # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"  # Allow TCP traffic
    ports    = ["80"] # Specifically allow port 80 (HTTP)
  }

  source_ranges = ["0.0.0.0/0"] # Allow traffic from anywhere (public internet)
}

############################################
# FIREWALL RULE: ALLOW INBOUND RDP TRAFFIC
############################################
resource "google_compute_firewall" "allow_postgres" {
  name    = "allow-postgres"                       # Name for the Postgres firewall rule
  network = google_compute_network.postgres_vpc.id # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"    # Allow TCP traffic
    ports    = ["5432"] # Port 5432 is used for Postgres
  }

  source_ranges = ["0.0.0.0/0"]      # Allow access from any IP address
  target_tags   = ["allow-postgres"] # Only applies to instances with the "allow-postgres" network tag
}

############################################
# FIREWALL RULE: ALLOW INBOUND SSH TRAFFIC
############################################
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"                            # Name for the SSH firewall rule
  network = google_compute_network.postgres_vpc.id # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"  # Allow TCP traffic
    ports    = ["22"] # Port 22 is used for Secure Shell (SSH) access
  }

  source_ranges = ["0.0.0.0/0"] # Allow SSH access from anywhere (can restrict later for security)
  target_tags   = ["allow-ssh"] # Only applies to instances tagged with "allow-ssh"
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.postgres_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.postgres_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}