// Variables
variable "consul_home" {
  type    = string
  default = "/opt/consul"
}

variable "consul_user" {
  type    = string
  default = "consul"
}

variable "consul_version" {
  type    = string
  default = "1.9.1"
}

variable "consul_template_version" {
  type    = string
  default = "0.25.1"
}

variable "node_exporter_home" {
  type    = string
  default = "/opt/node_exporter"
}

variable "node_exporter_user" {
  type    = string
  default = "node_exporter"
}

variable "node_exporter_version" {
  type    = string
  default = "1.0.1"
}

variable "packages" {
  type = list(string)
  default = [
    "curl",
    "jq",
    "unzip"
  ]
}

variable "source" {
  type = map(string)
  default = {
    description = "Base image - Ubuntu 20.04"
    image       = "ubuntu:focal"
    name        = "base-ubuntu-focal"
  }
}

variable "vault_approle_role" {
  type    = string
  default = "infra"
}

variable "vault_pki_mount" {
  type    = string
  default = "pki-intermediate-ca"
}

variable "vault_home" {
  type    = string
  default = "/opt/vault"
}

variable "vault_user" {
  type    = string
  default = "vault"
}

variable "vault_version" {
  type    = string
  default = "1.6.1"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

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

  // Add Consul config
  provisioner "file" {
    source      = "files/etc/consul"
    destination = "/etc/"
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

  provisioner "file" {
    source      = "files/etc/default/consul-template"
    destination = "/etc/default/consul-template"
  }

  // Add Consul Template service
  provisioner "file" {
    source      = "files/etc/systemd/system/consul-template.service"
    destination = "/etc/systemd/system/consul-template.service"
  }

  // Enable the service
  provisioner "shell" {
    inline = [
      "systemctl enable consul-template"
    ]
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
      "curl -ks $VAULT_ADDR/v1/${var.vault_pki_mount}/ca/pem | tee /etc/ssl/vault-ca.pem /usr/local/share/ca-certificates/vault-ca.pem && update-ca-certificates",
      "vault read -format=json auth/approle/role/${var.vault_approle_role}/role-id | jq -r '.data.role_id' >/etc/vault/.role_id",
      "vault write -f -format=json auth/approle/role/${var.vault_approle_role}/secret-id | jq -r '.data.secret_id' >/etc/vault/.secret_id"
    ]
  }
}
