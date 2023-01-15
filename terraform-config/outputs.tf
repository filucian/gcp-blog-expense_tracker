output "ip_address" {
  value     = google_compute_global_address.static.address
  sensitive = false
}

output "bucket" {
  value     = google_storage_bucket.tf_bucket.name
  sensitive = false
}

output "nameservers" {
  value     = flatten(google_dns_managed_zone.tf_zone.name_servers)
  sensitive = false
}
