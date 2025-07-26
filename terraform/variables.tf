variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "name" {
  type    = string
  default = "dtx-vm"
}

# Predefined machine type (ignored if custom_vcpus & custom_memory_mb are set)
variable "machine_type" {
  type        = string
  default     = "e2-medium"
  description = "E.g. e2-medium, n2-standard-2. Ignored if custom_vcpus/custom_memory_mb provided."
}

# Custom machine sizing (set both to use custom)
variable "custom_vcpus" {
  type        = number
  default     = null
  description = "Number of vCPUs for a custom machine type (null to skip)"
}

variable "custom_memory_mb" {
  type        = number
  default     = null
  description = "Memory in MB for a custom machine type (must be multiple of 256)"
}

variable "disk_size_gb" {
  type    = number
  default = 30
}

variable "username" {
  type    = string
  default = "dtx"
}

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key (ssh-ed25519 or ssh-rsa...)"
}

variable "network" {
  type    = string
  default = "default"
}

variable "ssh_source_ranges" {
  type    = list(string)
  default = ["0.0.0.0/0"] # tighten this!
}

variable "service_account_email" {
  type        = string
  default     = null
  description = "Optional SA email. Null means use the default Compute Engine SA."
  nullable    = true
}

variable "service_account_scopes" {
  type    = list(string)
  default = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "dtx"
}

variable "allowed_ports" {
  type        = list(number)
  description = "List of ports to open for ingress"
  default     = [22, 80, 443]
}

variable "secrets_json" {
  type        = map(string)
  description = "Map of secret keys and values to write to VM"
  sensitive   = true
}


