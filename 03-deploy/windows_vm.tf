############################################
# GOOGLE COMPUTE INSTANCE: DESKTOP VM
############################################

# Provisions a Windows-based VM using a Packer-built image
# Attached to a predefined VPC and subnet with public access via ephemeral IP
# Includes startup script execution via PowerShell
resource "google_compute_instance" "desktop_vm" {
  name         = "desktop-vm"              # Human-friendly name for this VM in the GCP console
  machine_type = "e2-standard-2"           # Cost-effective general-purpose machine type (2 vCPUs, 8 GB RAM)
  zone         = "us-central1-a"           # Deployment zone—must match the subnet’s region
  allow_stopping_for_update = true         # Allows Terraform to stop/start the VM safely during updates instead of recreating it

  ########################################
  # BOOT DISK CONFIGURATION
  ########################################

  # Use a Packer-created custom image as the boot disk OS image
  # Ensures the VM starts with a pre-configured environment (e.g., software, users)
  boot_disk {
    initialize_params {
      image = data.google_compute_image.desktop_packer_image.self_link  # Fully qualified link to the Packer-built desktop image
    }
  }

  ########################################
  # NETWORK INTERFACE CONFIGURATION
  ########################################

  # Attach to the defined VPC and subnetwork
  # Enables connectivity to other GCP services and the internet
  network_interface {
    network    = data.google_compute_network.packer_vpc.id        # Connects to existing VPC (data source must be defined elsewhere)
    subnetwork = data.google_compute_subnetwork.packer_subnet.id  # Ties instance to a specific subnet (CIDR must match deployment logic)
    access_config {}  # Creates and attaches a one-time ephemeral public IP (NAT-enabled) for remote desktop or updates
  }

  ########################################
  # STARTUP SCRIPT EXECUTION (WINDOWS)
  ########################################

  # Use metadata to deliver a PowerShell script to the Windows instance at boot time
  # The script is templated with dynamic variables such as the image name
  metadata = {
    windows-startup-script-ps1 = templatefile("./scripts/startup_script.ps1", {
      image = data.google_compute_image.desktop_packer_image.name  # Pass image name into startup script for reference/logging
    })
  }

  ########################################
  # FIREWALL TAGS
  ########################################

  # Tags used by firewall rules to allow inbound traffic
  # Must match target tags in `google_compute_firewall` rules (e.g., for RDP access)
  tags = ["allow-rdp"]  # Enables port 3389 access from the internet (used for Remote Desktop Protocol)
}

############################################
# OUTPUT: PUBLIC IP OF THE DESKTOP VM
############################################

# Outputs the public IP address of the provisioned desktop VM
# Useful for automation, dashboards, or manual access via RDP
output "desktop_public_ip" {
  value       = google_compute_instance.desktop_vm.network_interface[0].access_config[0].nat_ip  # Pulls the NAT-assigned public IP
  description = "The public IP address of the Desktop VM."  # Friendly label for downstream visibility
}
