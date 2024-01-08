provider "google" {
  project = "test-vpn-server-406613"
}

# Define the number of VMs and their zones as variables
variable "number_of_vms" {
  description = "Number of VM instances to create"
  type        = number
  default     = 32
}

variable "vm_zones" {
  description = "Zones for the VM instances"
  type        = list(string)
  default     = ["us-east1-b", "us-east4-c", "us-central1-c", "us-west1-b", "europe-west4-a", "europe-west4-b", "europe-west1-b", "europe-west1-c", "europe-west2-c", "asia-east1-b", "asia-southeast1-b", "asia-northeast1-b", "asia-south1-c", "australia-southeast1-b", "southamerica-east1-b", "asia-east2-a", "asia-northeast2-a", "asia-northeast3-a", "asia-south2-a", "europe-central2-a", "europe-north1-a", "europe-southwest1-a", "europe-west10-a", "europe-west12-a", "europe-west6-a", "europe-west8-a", "europe-west9-a", "me-central1-a", "me-west1-a", "northamerica-northeast1-a", "southamerica-west1-a"]
}

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
  default     = "test-vpn-server-406613"
}

# VM Instances
resource "google_compute_instance" "test-vpn-server" {
  count = var.number_of_vms

  name = "test-vpn-server-${format("%03d", count.index + 1)}"
  zone = element(var.vm_zones, count.index % length(var.vm_zones))

  boot_disk {
    auto_delete = true
    device_name = "test-vpn-server-${count.index + 1}"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20231030"
      size  = 35
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-medium"

  metadata = {
  ssh-keys= ""
}

  network_interface {
    access_config {
      network_tier = "PREMIUM"
   }

  subnetwork = "projects/${var.project_id}/regions/${join("-", slice(split("-", element(var.vm_zones, count.index % length(var.vm_zones))), 0, 2))}/subnetworks/default"

  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = ""
    scopes = [""]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["test-vpn-server-tag"]

}

# Google Cloud Storage Bucket
resource "google_storage_bucket" "test-ip-rotation_vpn-configs" {
  name          = "test-ip-address-rotation_vpn-configs"
  location      = "US"
  force_destroy = true # Allows Terraform to delete the bucket even if it contains objects
  storage_class = "STANDARD"
}

# Granting Storage Object Admin role to the service account
resource "google_project_iam_member" "service_account_storage_admin" {
  project = "test-vpn-server-406613"
  role    = "roles/storage.admin"
  member  = ""
}

# Granting Storage Downloader role to 'allUsers'
resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.test-ip-rotation_vpn-configs.name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers",
  ]
}

output "instance_ips" {
  value = [for instance in google_compute_instance.test-vpn-server : instance.network_interface[0].access_config[0].nat_ip]
}

