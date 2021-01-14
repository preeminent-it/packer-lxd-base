pid_file        = "/var/run/vault-agent.pid"
exit_after_auth = false

vault {
  address = "https://vault.service.dc1.consul:8200"
  ca_path = "/etc/ssl/certs"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path                   = "/etc/vault/.role_id"
      secret_id_file_path                 = "/etc/vault/.secret_id"
      remove_secret_id_file_after_reading = true
    }
  }
  sink "file" {
    config = {
      path = "/root/.vault_token"
      mode = 0600
    }
  }
}

template {
  source      = "/etc/vault/templates/vault_key.ctmpl"
  destination = "/etc/consul/tls/client.key"
}

template {
  source      = "/etc/vault/templates/vault_certificate.ctmpl"
  destination = "/etc/consul/tls/client.crt"
}


