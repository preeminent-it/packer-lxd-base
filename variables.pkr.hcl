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

variable "promtail_home" {
  type    = string
  default = "/opt/promtail"
}

variable "promtail_user" {
  type    = string
  default = "promtail"
}

variable "promtail_version" {
  type    = string
  default = "2.1.0"
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
