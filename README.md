# Packer LXD - Base

## Build
```bash
packer build .
```

## Requirements
* packer 1.6.6 (or earlier supporting hcl2)
* a working lxd installation

No requirements.

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| consul\_home | Variables | `string` | `"/opt/consul"` | no |
| consul\_template\_version | n/a | `string` | `"0.25.1"` | no |
| consul\_user | n/a | `string` | `"consul"` | no |
| consul\_version | n/a | `string` | `"1.9.1"` | no |
| node\_exporter\_home | n/a | `string` | `"/opt/node_exporter"` | no |
| node\_exporter\_user | n/a | `string` | `"node_exporter"` | no |
| node\_exporter\_version | n/a | `string` | `"1.0.1"` | no |
| packages | n/a | `list(string)` | <pre>[<br>  "curl",<br>  "jq",<br>  "unzip"<br>]</pre> | no |
| source | n/a | `map(string)` | <pre>{<br>  "description": "Base image - Ubuntu 20.04",<br>  "image": "ubuntu:focal",<br>  "name": "base-ubuntu-focal"<br>}</pre> | no |
| vault\_approle\_role | n/a | `string` | `"infra"` | no |
| vault\_home | n/a | `string` | `"/opt/vault"` | no |
| vault\_pki\_mount | n/a | `string` | `"pki-intermediate-ca"` | no |
| vault\_user | n/a | `string` | `"vault"` | no |
| vault\_version | n/a | `string` | `"1.6.1"` | no |
