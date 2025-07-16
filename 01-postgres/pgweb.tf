# Compute Instance: Ubuntu VM
# Deploys a lightweight Ubuntu 24.04 VM with essential configurations.
resource "google_compute_instance" "pgweb_vm" {
  name         = "pgweb-vm"      # Name of the instance.
  machine_type = "e2-micro"      # Machine type for cost-efficient workloads.
  zone         = "us-central1-a" # Deployment zone for the instance.

  # Boot Disk Configuration
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_latest.self_link # Specifies the latest Ubuntu image.
    }
  }

  network_interface {
    network    = google_compute_network.postgres_vpc.id
    subnetwork = google_compute_subnetwork.postgres_subnet.id
    access_config {}
  }

  metadata_startup_script = templatefile("./scripts/pgweb.sh.template", {
    PGPASSWORD = random_password.postgres.result,
    PGENDPOINT = google_sql_database_instance.postgres.private_ip_address
  })


  # Tags for Firewall Rules
  tags = ["allow-ssh", "allow-http"] # Tags to match firewall rules for SSH and HTTP access.

  # Service Account Configuration
  service_account {
    email  = local.credentials.client_email
    scopes = ["cloud-platform"] # Grants access to all Google Cloud APIs.
  }

  depends_on = [google_sql_database_instance.postgres]
}

# Data Source: Ubuntu Image
# Fetches the latest Ubuntu 24.04 LTS image from the official Ubuntu Cloud project.
data "google_compute_image" "ubuntu_latest" {
  family  = "ubuntu-2404-lts-amd64" # Specifies the Ubuntu image family.
  project = "ubuntu-os-cloud"       # Google Cloud project hosting the image.
}
