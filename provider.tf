terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.10.0"
    }
  }
}

provider "google" {
  # alias       = "my_provider"
  credentials = file("./keys.json")
  project     = "terraform-gcp-410313"
  region      = "us-central1"
}
