// Image
source "lxd" "main" {
  image        = "${var.source.image}"
  output_image = "${var.source.name}"
  publish_properties = {
    description = "${var.source.description}"
  }
}

// Build
build {
  sources = ["source.lxd.main"]

  // Update and install packages
  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq ${join(" ", var.packages)} < /dev/null > /dev/null"
    ]
  }

  // Create Node Exporter system user
  provisioner "shell" {
    inline = [
      "useradd --system --home ${var.node_exporter_home} --shell /bin/false ${var.node_exporter_user}"
    ]
  }

  // Install node_exporter
  provisioner "shell" {
    inline = [
      "curl -sLo - https://github.com/prometheus/node_exporter/releases/download/v${var.node_exporter_version}/node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz | \n",
      "tar -zxf - --strip-component=1 -C /usr/local/bin/ node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter"
    ]
  }

  // Add Node Exporter service
  provisioner "file" {
    source      = "files/etc/systemd/system/node_exporter.service"
    destination = "/etc/systemd/system/node_exporter.service"
  }

  // Enable the service
  provisioner "shell" {
    inline = [
      "systemctl enable node_exporter"
    ]
  }

  // Create Promtail system user
  provisioner "shell" {
    inline = [
      "useradd --system --home ${var.promtail_home} --shell /bin/false ${var.promtail_user}"
    ]
  }

  // Install promtail
  provisioner "shell" {
    inline = [
      "curl -sLO https://github.com/grafana/loki/releases/download/v${var.promtail_version}/promtail-linux-amd64.zip &&",
      "unzip promtail-linux-amd64.zip promtail-linux-amd64 && mv promtail-linux-amd64 /usr/local/bin/promtail &&",
      "rm promtail-linux-amd64.zip"
    ]
  }

  // Add Promtail config
  provisioner "file" {
    source      = "files/etc/promtail"
    destination = "/etc/"
  }

  // Add Promtail service
  provisioner "file" {
    source      = "files/etc/systemd/system/promtail.service"
    destination = "/etc/systemd/system/promtail.service"
  }

  // Allow Promtail to read /var/log
  provisioner "shell" {
    inline = [
      "setfacl -dRm g:${var.promtail_user}:rX,g:${var.promtail_user}:rX /var/log"
    ]
  }

  // Enable the service
  provisioner "shell" {
    inline = [
      "systemctl enable promtail"
    ]
  }

  // Create directories for Consul
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/consul/tls ${var.consul_home}"
    ]
  }

  // Create Consul system user
  provisioner "shell" {
    inline = [
      "useradd --system --home ${var.consul_home} --shell /bin/false ${var.consul_user}"
    ]
  }

  // Install Consul
  provisioner "shell" {
    inline = [
      "curl -sO https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip &&",
      "unzip consul_${var.consul_version}_linux_amd64.zip consul -d /usr/local/bin/ &&",
      "rm consul_${var.consul_version}_linux_amd64.zip"
    ]
  }

  provisioner "file" {
    source      = "files/etc/profile.d/consul.sh"
    destination = "/etc/profile.d/consul.sh"
  }

  // Add Consul service
  provisioner "file" {
    source      = "files/etc/systemd/system/consul.service"
    destination = "/etc/systemd/system/consul.service"
  }

  // Set file ownership and enable the service
  provisioner "shell" {
    inline = [
      "chown -R ${var.consul_user}: /etc/consul ${var.consul_home}",
      "systemctl enable consul"
    ]
  }

  // Install Consul Template
  provisioner "shell" {
    inline = [
      "curl -sO https://releases.hashicorp.com/consul-template/${var.consul_template_version}/consul-template_${var.consul_template_version}_linux_amd64.zip &&",
      "unzip consul-template_${var.consul_template_version}_linux_amd64.zip consul-template -d /usr/local/bin/ &&",
      "rm consul-template_${var.consul_template_version}_linux_amd64.zip"
    ]
  }

  // Add Consul Template config
  provisioner "file" {
    source      = "files/etc/consul-template"
    destination = "/etc/"
  }

  // Create directories for Vault
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/vault/tls ${var.vault_home}"
    ]
  }

  // Create Vault system user
  provisioner "shell" {
    inline = [
      "useradd --system --home ${var.vault_home} --shell /bin/false ${var.vault_user}"
    ]
  }

  // Install Vault
  provisioner "shell" {
    inline = [
      "curl -sO https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_amd64.zip &&",
      "unzip vault_${var.vault_version}_linux_amd64.zip vault -d /usr/local/bin/ &&",
      "setcap cap_ipc_lock=+ep /usr/local/bin/vault &&",
      "rm vault_${var.vault_version}_linux_amd64.zip"
    ]
  }

  // Add Vault config
  provisioner "file" {
    source      = "files/etc/vault"
    destination = "/etc/"
  }

  // Add Vault service
  provisioner "file" {
    source      = "files/etc/systemd/system/vault.service"
    destination = "/etc/systemd/system/vault.service"
  }

  // Set file ownership and enable the service
  provisioner "shell" {
    inline = [
      "chown -R ${var.vault_user}: /etc/vault ${var.vault_home}",
      "systemctl enable vault"
    ]
  }

  // Add CA certificates and auth for Vault
  provisioner "shell" {
    environment_vars = [
      "VAULT_ADDR=$VAULT_ADDR",
      "VAULT_SKIP_VERIFY=$VAULT_SKIP_VERIFY",
      "VAULT_TOKEN=$VAULT_TOKEN"
    ]
    inline = [
      "curl -ks $VAULT_ADDR/v1/${var.vault_pki_mount}/ca/pem | tee /etc/ssl/vault-ca.crt /usr/local/share/ca-certificates/vault-ca.crt && update-ca-certificates",
      "vault read -format=json auth/approle/role/${var.vault_approle_role}/role-id | jq -r '.data.role_id' >/etc/vault/.role_id",
      "vault write -f -format=json auth/approle/role/${var.vault_approle_role}/secret-id | jq -r '.data.secret_id' >/etc/vault/.secret_id"
    ]
  }
}
