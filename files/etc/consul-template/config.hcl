reload_signal = "SIGHUP"
kill_signal   = "SIGINT"
max_stale     = "10m"
log_level     = "info"
pid_file      = "/var/run/consul-template.pid"

vault {
  address                = "vault.lxd"
  vault_agent_token_file = "/root/.vault-agent"
  renew_token            = true
}

wait {
  min = "60s"
  max = "180s"
}
