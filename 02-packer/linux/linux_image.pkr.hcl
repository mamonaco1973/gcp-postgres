packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.6"
    }
  }
}
############################################
# LOCALS: TIMESTAMP UTILITY
############################################

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") # Generate compact timestamp (YYYYMMDDHHMMSS)
                                                       # Used for unique image names
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "source_image_family" {
  description = "Source image family to base the build on (e.g., ubuntu-2404-lts-amd64)"
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}

variable "password" {
  description = "The password for the packer account"    # Will be passed into SSH provisioning script
  default     = ""                                       # Must be overridden securely via env or CLI
}

source "googlecompute" "packer_build_image" {
  project_id            = var.project_id
  zone                  = var.zone
  source_image_family   = var.source_image_family # Specifies the base image family
  ssh_username          = "ubuntu"                # Specify the SSH username
  machine_type          = "e2-micro"              # Smallest machine type for cost-effectiveness

  image_name            = "games-image-${local.timestamp}" # Use local.timestamp directly
  image_family          = "games-images"          # Image family to group related images
  disk_size             = 20                      # Disk size in GB
}

build {
  sources = ["source.googlecompute.packer_build_image"]

  # Create a temp directory for HTML files
  provisioner "shell" {
    inline = ["mkdir -p /tmp/html"]                      # Ensure target directory exists on VM
  }

  # Copy local HTML files to the instance
  provisioner "file" {
    source      = "./html/"                              # Source directory from local machine
    destination = "/tmp/html/"                           # Target directory inside VM
  }

  # Run install script inside the instance
  provisioner "shell" {
    script = "./install.sh"                              # Installs and configures required packages
  }

  # Run SSH configuration script, passing in a password variable
  provisioner "shell" {
    script = "./config_ssh.sh"                           # Custom script to enable SSH password login
    environment_vars = [
      "PACKER_PASSWORD=${var.password}"                  # Export password to the script environment
    ]
  }
}
