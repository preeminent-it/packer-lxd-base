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

variable "node_exporter_version" {
  type    = string
  default = "1.0.1"
}

variable "packages" {
  type    = list(string)
  default = [
    "curl",
    "unzip"
  ]
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
source "lxd" "base-ubuntu-focal" {
  image        = "images:ubuntu/focal"
  output_image = "base-ubuntu-focal"
  publish_properties = {
    description = "Base - Ubuntu Focal"
  }
}

// Build
build {
  sources = ["source.lxd.base-ubuntu-focal"]

  // Update and install packages
  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq ${join(" ", var.packages)} < /dev/null > /dev/null"
    ]
  }

  // Install node_exporter
  provisioner "shell" {
    inline = [
      "curl -sLo - https://github.com/prometheus/node_exporter/releases/download/v${var.node_exporter_version}/node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz | \n",
      "tar -zxf - --strip-component=1 -C /usr/local/bin/ node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter"
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

  // Create self-signed certificate
  provisioner "shell" {
    inline = [
      "openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/consul/tls/cli.key -out /etc/consul/tls/cli.crt -subj \"/CN=consul-cli\"",
      "openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/consul/tls/client.key -out /etc/consul/tls/client.crt -subj \"/CN=consul-client\""
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
    source      = "files/etc/consul/consul.hcl"
    destination = "/etc/consul/consul.hcl"
  }

  // Add Consul service
  provisioner "file" {
    source      = "files/etc/systemd/system/consul.service"
    destination = "/etc/systemd/system/consul.service"
  }

  // Set file ownership and enable the service
  provisioner "shell" {
    inline = [
      "chown -R ${var.consul_user} /etc/consul ${var.consul_home}",
      "systemctl enable consul"
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

  // Create self-signed certificate
  provisioner "shell" {
    inline = [
      "openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/vault/tls/server.key -out /etc/vault/tls/server.crt -subj \"/CN=vault\""
    ]
  }

  // Install Vault
  provisioner "shell" {
    inline = [
      "curl -sO https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_amd64.zip &&",
      "unzip vault_${var.vault_version}_linux_amd64.zip vault -d /usr/local/bin/ &&",
      "rm vault_${var.vault_version}_linux_amd64.zip"
    ]
  }

  // Add Vault config
  provisioner "file" {
    source      = "files/etc/vault/agent.hcl"
    destination = "/etc/vault/agent.hcl"
  }

  // Add Vault service
  provisioner "file" {
    source      = "files/etc/systemd/system/vault-agent.service"
    destination = "/etc/systemd/system/vault-agent.service"
  }

  // Set file ownership and enable the service
  provisioner "shell" {
    inline = [
      "chown -R ${var.vault_user} /etc/vault ${var.vault_home}",
      "systemctl enable vault-agent"
    ]
  }
}
