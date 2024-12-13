ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
  tls_skip_verify = "true"
  tls_require_and_verify_client_cert = "false"
}

storage "mysql" {
  address  = "${MYSQL_HOST}:${MYSQL_PORT}"
  username = "${MYSQL_USER}"
  password = "${MYSQL_PASSWORD}"
  database = "${MYSQL_DATABASE}"
}

scheme = "http"
api_addr     = "${VAULT_API_ADDR}"
cluster_addr = "${VAULT_CLUSTER_ADDR}"

disable_mlock = true