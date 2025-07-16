############################################
# INPUT VARIABLES: NETWORK RESOURCES
############################################

# Defines a string input variable for the name of the existing VPC
# Allows flexibility across environments by avoiding hardcoded VPC names
variable "vpc_name" {
  description = "Name of the existing VPC network"  # Describes the purpose of this input (critical for modular deployments)
  type        = string                              # Ensures only string values are accepted
  default     = "packer-vpc"
}

# Defines a string input variable for the name of the existing subnet
# Enables reusability of the module in any region or VPC structure
variable "subnet_name" {
  description = "Name of the existing subnetwork"   # Clear description for input validation and documentation
  type        = string                              # Must be a valid string representing the subnet name
  default     = "packer-subnet"
}

############################################
# INPUT VARIABLES: PACKER IMAGE NAMES
############################################

# Name of the Packer-built image used for launching "games" VM instances
# Passed in externally so the infrastructure is decoupled from hardcoded image names
variable "games_image_name" {
  description = "Name of the Packer built games image"  # Explicitly describes the image being referenced
  type        = string                                  # Must be a string; typically something like "games-ubuntu-20240418"
}

# Data source to lookup the actual image object in GCP based on the name and project
# Ensures that Terraform can retrieve the image metadata and use it for VM boot disks
data "google_compute_image" "games_packer_image" {
  name    = var.games_image_name               # Dynamically reference the image name provided by the variable
  project = local.credentials.project_id       # Use the project ID from the decoded credentials (avoids hardcoding)
}

# Name of the Packer-built image used for launching "desktop" VM instances
variable "desktop_image_name" {
  description = "Name of the Packer built desktop image"  # Describes purpose of the image name
  type        = string                                    # Must be a valid string; typically "desktop-windows-20240418"
}

# Data source to lookup the actual desktop image in GCP by name
# Needed so Terraform can retrieve the image ID for boot disk provisioning
data "google_compute_image" "desktop_packer_image" {
  name    = var.desktop_image_name             # Dynamically pulls image name from variable
  project = local.credentials.project_id       # Same GCP project context as defined by credentials
}
