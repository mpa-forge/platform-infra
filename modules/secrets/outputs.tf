output "secret_ids" {
  description = "Secret ids keyed by logical name."
  value = {
    for logical_name, secret in google_secret_manager_secret.this :
    logical_name => secret.secret_id
  }
}
