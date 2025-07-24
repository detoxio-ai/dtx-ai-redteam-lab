terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  # Uses Application Default Credentials by default (gcloud auth application-default login)
}

# Grab the latest Ubuntu 22.04 LTS image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# Decide machine type (predefined vs custom)
locals {
  machine_type = (var.custom_vcpus != null && var.custom_memory_mb != null) ? "custom-${var.custom_vcpus}-${var.custom_memory_mb}" : var.machine_type
}


# Render startup script to create the user & inject key
data "template_file" "startup" {
  template = file("${path.module}/startup.sh.tpl")
  vars = {
    username       = var.username
    ssh_public_key = var.ssh_public_key
  }
}

resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "dtx-vm-${count.index + 1}"
  machine_type = local.machine_type
  zone         = var.zone
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network       = var.network
    access_config {}
  }

  metadata = {
    block-project-ssh-keys = "true"
  }

  metadata_startup_script = data.template_file.startup.rendered

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }
}


# Simple firewall to allow SSH from anywhere (lock this down for prod!)
resource "google_compute_firewall" "ssh" {
  name    = "${var.name}-allow-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
}

