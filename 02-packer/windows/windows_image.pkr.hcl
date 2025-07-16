############################################
#              PACKER SETUP
############################################

packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.0"
    }
    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = "0.15.0"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") # Generate compact timestamp (YYYYMMDDHHMMSS)
                                                       # Used for unique image names
}

############################################
#           PARAMETER VARIABLES
############################################

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
  description = "Windows image family (e.g., windows-2022)"
  type        = string
  default     = "windows-2022"
}

variable "password" {
  description = "Password for the Windows Administrator account"
  type        = string
}

variable "vpc" {
  description = "vpc"
  type        = string
  default     = "packer-vpc"
}

variable "subnet" {
  description = "subnet"
  type        = string
  default     = "packer-subnet"
}

############################################
#      MAIN SOURCE BLOCK - GCP WINDOWS IMAGE
############################################

source "googlecompute" "windows_image" {
  project_id            = var.project_id
  zone                  = var.zone
  machine_type          = "e2-standard-4"
  source_image_family   = var.source_image_family
  disk_size             = 128
  disk_type             = "pd-balanced"
  image_name            = "desktop-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  image_family          = "desktop-images"   
  communicator          = "winrm"
  winrm_username        = "packer_user"  
  winrm_password        = var.password
  winrm_insecure = true             
  winrm_use_ntlm = true             
  winrm_use_ssl  = true             
  
  network               = var.vpc
  subnetwork            = var.subnet
  
  metadata = {
    windows-startup-script-cmd = <<EOT
        winrm quickconfig -quiet ^
        && net user packer_user "${var.password}" /add /Y ^
        && net localgroup administrators packer_user /add ^
        && winrm set winrm/config/service/auth @{Basic="true"}
    EOT
  }

  tags = ["allow-winrm","allow-rdp"]
}

############################################
#             BUILD PROCESS
############################################

build {
  sources = ["source.googlecompute.windows_image"]

  provisioner "windows-update" {}

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
    script = "./security.ps1"
    environment_vars = [
      "PACKER_PASSWORD=${var.password}"
    ]
  }

  provisioner "powershell" {
    inline = [
      "mkdir C:\\mcloud"
    ]
  }

  provisioner "file" {
    source      = "./boot.ps1"
    destination = "C:\\mcloud\\"
  }

  provisioner "powershell" {
    script = "./chrome.ps1"
  }

  provisioner "powershell" {
    script = "./firefox.ps1"
  }

  provisioner "powershell" {
    script = "./desktop.ps1"
  }

  # Final Step: Generalize Windows with Sysprep for image reuse on GCP
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep for GCP image finalization...'",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /generalize /shutdown /quiet"
    ]
  }
}
