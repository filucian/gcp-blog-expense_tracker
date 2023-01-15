resource "google_dns_managed_zone" "tf_zone" {
  name        = "tf-managed-zone"
  dns_name    = "${var.domain}."
  visibility  = "public"
  description = "Zone for tf-vite app"
}

resource "google_dns_record_set" "a" {
  name = google_dns_managed_zone.tf_zone.dns_name
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.tf_zone.name

  rrdatas = [google_compute_global_address.static.address]
}

resource "google_dns_record_set" "cname" {
  name = "www.${google_dns_managed_zone.tf_zone.dns_name}"
  type = "CNAME"
  ttl  = 300

  managed_zone = google_dns_managed_zone.tf_zone.name

  rrdatas = [google_dns_managed_zone.tf_zone.dns_name]
}
