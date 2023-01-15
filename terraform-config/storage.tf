resource "google_storage_bucket" "tf_bucket" {
  name     = "tf-bucket-${random_id.suffix.hex}"
  location = var.gcp_region
  website {
    main_page_suffix = "index.html"
  }
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "public_bucket" {
  bucket  = google_storage_bucket.tf_bucket.name
  role    = "roles/storage.objectViewer"
  members = ["allUsers"]
}

resource "random_id" "suffix" {
  byte_length = 4
}
