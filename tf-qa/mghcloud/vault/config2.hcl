storage "mysql" {
  address = "201.205.178.45:30005"
  username = "root"
  password = "change_me"
  database = "vaultdb"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
  tls_skip_verify = "true"
  tls_require_and_verify_client_cert = "false"
}
