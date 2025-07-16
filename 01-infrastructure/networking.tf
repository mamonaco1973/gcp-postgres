############################################
# CUSTOM VPC: DEFINES ISOLATED NETWORK
############################################
resource "google_compute_network" "packer_vpc" {
  name                    = "packer-vpc"               # Name for the custom VPC
  auto_create_subnetworks = false                      # Disables auto-created subnets so we can define explicit subnet structure
}

############################################
# CUSTOM SUBNET: DEFINES INTERNAL IP RANGE
############################################
resource "google_compute_subnetwork" "packer_subnet" {
  name          = "packer-subnet"                      # Name for the custom subnet
  ip_cidr_range = "10.0.0.0/24"                        # Internal IP range (256 IPs total)
  region        = "us-central1"                        # Region where the subnet will be created
  network       = google_compute_network.packer_vpc.id # Connects this subnet to the custom VPC
}

############################################
# FIREWALL RULE: ALLOW INBOUND HTTP TRAFFIC
############################################
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"                               # Name for the HTTP firewall rule
  network = google_compute_network.packer_vpc.id       # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"                                   # Allow TCP traffic
    ports    = ["80"]                                  # Specifically allow port 80 (HTTP)
  }

  source_ranges = ["0.0.0.0/0"]                        # Allow traffic from anywhere (public internet)
}

############################################
# FIREWALL RULE: ALLOW INBOUND RDP TRAFFIC
############################################
resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"                               # Name for the RDP firewall rule
  network = google_compute_network.packer_vpc.id      # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"                                  # Allow TCP traffic
    ports    = ["3389"]                               # Port 3389 is used for Windows Remote Desktop (RDP)
  }

  source_ranges = ["0.0.0.0/0"]                       # Allow access from any IP address
  target_tags   = ["allow-rdp"]                       # Only applies to instances with the "allow-rdp" network tag
}

############################################
# FIREWALL RULE: ALLOW INBOUND SSH TRAFFIC
############################################
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"                               # Name for the SSH firewall rule
  network = google_compute_network.packer_vpc.id      # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"                                  # Allow TCP traffic
    ports    = ["22"]                                 # Port 22 is used for Secure Shell (SSH) access
  }

  source_ranges = ["0.0.0.0/0"]                       # Allow SSH access from anywhere (can restrict later for security)
  target_tags   = ["allow-ssh"]                       # Only applies to instances tagged with "allow-ssh"
}

############################################
# FIREWALL RULE: ALLOW INBOUND WINRM TRAFFIC
############################################
resource "google_compute_firewall" "allow_winrm" {
  name    = "allow-winrm"                             # Name for the SSH firewall rule
  network = google_compute_network.packer_vpc.id      # Applies rule to the defined custom VPC

  allow {
    protocol = "tcp"                                  # Allow TCP traffic
    ports    = ["5986"]                               # Port 5986 for WinRM traffic
  }

  source_ranges = ["0.0.0.0/0"]                       # Allow SSH access from anywhere (can restrict later for security)
  target_tags   = ["allow-winrm"]                     # Only applies to instances tagged with "allow-ssh"
}
