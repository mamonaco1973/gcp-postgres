############################################
# GOOGLE COMPUTE INSTANCE: GAMES VM
############################################

# Creates a low-cost, publicly accessible virtual machine instance
# Based on a custom Packer image, attached to existing VPC and subnet
resource "google_compute_instance" "games_vm" {
  name         = "games-vm"              # Human-readable name for the VM in the GCP console
  machine_type = "e2-micro"              # Ultra-cheap VM type (shared CPU, ideal for light workloads)
  zone         = "us-central1-a"         # Specific availability zone for this instance (must match subnet region)
  allow_stopping_for_update = true       # Allows the instance to be stopped temporarily during updates (saves cost and prevents rebuilds)

  ########################################
  # BOOT DISK CONFIGURATION
  ########################################

  # Define the boot disk for the VM using a custom Packer image
  # Ensures consistent VM setup with pre-installed software or config baked into the image
  boot_disk {
    initialize_params {
      image = data.google_compute_image.games_packer_image.self_link  # Reference the full self_link to the image from earlier data block
    }
  }

  ########################################
  # NETWORK INTERFACE CONFIGURATION
  ########################################

  # Attach the VM to an existing VPC and subnetwork
  # Required for the VM to have internal and external connectivity
  network_interface {
    network    = data.google_compute_network.packer_vpc.id        # Reference the VPC ID from the data lookup
    subnetwork = data.google_compute_subnetwork.packer_subnet.id  # Reference the subnet ID for IP range allocation

    access_config {}  # Creates and attaches an ephemeral public IP (via NAT) to the VM for internet access
  }

  ########################################
  # STARTUP SCRIPT EXECUTION
  ########################################

  # Pass a startup script to the VM to execute on boot
  # Uses templatefile() to inject dynamic values (e.g., image name) into the script at runtime
  metadata_startup_script = templatefile("./scripts/startup_script.sh", {
    image = data.google_compute_image.games_packer_image.name  # Injects the image name into the script as a variable
  })

  ########################################
  # FIREWALL TAGS
  ########################################

  # Attach tags used by firewall rules to permit specific traffic (e.g., SSH, HTTP)
  # These tags must match firewall rule target tags defined elsewhere
  tags = ["allow-ssh", "allow-http"]  # Enable SSH (port 22) and HTTP (port 80) traffic into this VM
}

############################################
# OUTPUT: PUBLIC IP OF THE GAMES VM
############################################

# Exposes the public IP address of the newly created VM
# Useful for SSH access, web app testing, or automation outputs
output "games_public_ip" {
  value       = google_compute_instance.games_vm.network_interface[0].access_config[0].nat_ip  # Fetch the NAT-assigned external IP
  description = "The public IP address of the Game VM."  # Provides human-friendly context for the output
}
