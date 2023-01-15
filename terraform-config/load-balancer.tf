resource "google_compute_global_address" "static" {
  name = "tf-ip-address"
}

resource "google_compute_backend_bucket" "tf_backend_bucket" {
  name        = "tf-backend-bucket"
  description = "Contains beautiful images"
  bucket_name = google_storage_bucket.tf_bucket.name
  enable_cdn  = true

  cdn_policy {
    cache_mode = "CACHE_ALL_STATIC"
  }
}

resource "google_compute_url_map" "tf_load_balancer" {
  name        = "tf-load-balancer"
  description = "Load Balancer to serve Vite app"

  default_service = google_compute_backend_bucket.tf_backend_bucket.id
}

resource "google_compute_target_http_proxy" "target_proxy" {
  name    = "tf-load-balancer-proxy"
  url_map = google_compute_url_map.tf_load_balancer.id
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "tf-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  # network_tier          = "PREMIUM"
  ip_address = google_compute_global_address.static.id
  # allow_global_access = true
  target     = google_compute_target_http_proxy.target_proxy.id
  port_range = "80"
}
