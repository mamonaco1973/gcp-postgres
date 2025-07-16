resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance"
  database_version = "POSTGRES_15"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.postgres_vpc.self_link
    }

    backup_configuration {
      enabled = true
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  deletion_protection = false
}

resource "google_sql_user" "postgres_user" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres.result
}

resource "google_dns_managed_zone" "private_dns" {
  name       = "internal-db-zone"
  dns_name   = "internal.db-zone.local." # MUST end in dot
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.postgres_vpc.id
    }
  }

  description = "Private DNS zone for internal PostgreSQL database"
}


resource "google_dns_record_set" "postgres_dns" {
  name         = "postgres.internal.db-zone.local." # MUST end in dot
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_dns.name

  rrdatas = [google_sql_database_instance.postgres.private_ip_address]
}
