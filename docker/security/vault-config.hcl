ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true  # TLS handled by Traefik
}

storage "file" {
  path = "/vault/data"
}

api_addr     = "https://vault.duoowatch.com"
cluster_addr = "https://vault.duoowatch.com:8201"
