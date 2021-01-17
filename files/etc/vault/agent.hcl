pid_file        = "/var/run/vault-agent.pid"
exit_after_auth = false

vault {
  address = "https://vault.lxd:8200"
  ca_path = "/etc/ssl/certs"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path                   = "/etc/vault/.role_id"
      secret_id_file_path                 = "/etc/vault/.secret_id"
      remove_secret_id_file_after_reading = false
    }
  }
  sink "file" {
    config = {
      path = "/root/.vault_token"
      mode = 0600
    }
  }
}
