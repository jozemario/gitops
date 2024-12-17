ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
  tls_require_and_verify_client_cert = false
}

storage "file" {
  path = "/vault/file"
}

api_addr = "http://201.205.178.45:30300"
cluster_addr = "http://201.205.178.45:30301"

disable_mlock = true