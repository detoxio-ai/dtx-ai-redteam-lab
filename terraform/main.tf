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
}

# -------- LOCALS --------
locals {
  workspace_suffix = terraform.workspace == "default" ? "" : "-${terraform.workspace}"

  machine_type = (
    var.custom_vcpus != null && var.custom_memory_mb != null
    ? "custom-${var.custom_vcpus}-${var.custom_memory_mb}"
    : var.machine_type
  )

  startup_script = templatefile("${path.module}/startup.sh.tpl", {
    username       = var.username
    ssh_public_key = var.ssh_public_key
    secrets_json   = var.secrets_json
  })
}

# -------- VPC + NAT SETUP --------

resource "google_compute_network" "vpc" {
  name                    = "${var.prefix}${local.workspace_suffix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.prefix}${local.workspace_suffix}-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = "10.10.0.0/16"
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "${var.prefix}${local.workspace_suffix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}${local.workspace_suffix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# -------- IMAGE --------

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# -------- VM INSTANCE --------

resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.prefix}${local.workspace_suffix}-vm-${count.index + 1}"
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
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata = {
    block-project-ssh-keys = "true"
  }

  metadata_startup_script = local.startup_script

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }
}

# -------- FIREWALL RULES --------

resource "google_compute_firewall" "allow_custom_ports" {
  name    = "${var.prefix}${local.workspace_suffix}-allow-ports"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = [for port in var.allowed_ports : tostring(port)]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
}

