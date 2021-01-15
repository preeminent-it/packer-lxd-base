acl = {
  enabled                  = true
  default_policy           = "allow"
  enable_token_persistence = true
}

auto_encrypt = {
  tls = true
}

ports = {
  http  = -1
  https = 8501
}

server                 = false
bind_addr              = "{{ GetInterfaceIP \"eth0\" }}"
client_addr            = "0.0.0.0"
retry_join             = ["consul.lxd"]
datacenter             = "dc1"
data_dir               = "/opt/consul"
encrypt                = "qDOPBEr+/oUVeOFQOnVypxwDaHzLrD+lvjo5vCEBbZ0="
ca_file                = "/etc/ssl/vault-ca.pem"
cert_file              = "/etc/consul/tls/client.crt"
key_file               = "/etc/consul/tls/client.key"
verify_incoming        = true
verify_outgoing        = true
verify_server_hostname = true
