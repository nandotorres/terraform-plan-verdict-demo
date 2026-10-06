# A mock "service" built entirely from cloud-free providers
# (random, local, terraform_data) so it plans and applies in CI with no
# credentials and no real infrastructure.
#
# Drive the demo by editing infra/terraform.tfvars in a pull request.
terraform {
  required_providers {
    random = { source = "hashicorp/random" }
    local  = { source = "hashicorp/local" }
  }
}

variable "replicas" {
  description = "Number of app instances."
  type        = number
  default     = 10
}

variable "image_tag" {
  description = "Changing this triggers an in-place update of every instance."
  type        = string
  default     = "v1"
}

variable "config_version" {
  description = "Changing this forces every instance to be replaced."
  type        = string
  default     = "1"
}

variable "ingress_cidr" {
  description = "Allowed ingress range. Set to 0.0.0.0/0 to trigger a security hit."
  type        = string
  default     = "10.0.0.0/8"
}

resource "random_pet" "service" {
  length = 2
}

resource "terraform_data" "app" {
  count            = var.replicas
  input            = var.image_tag      # change -> update
  triggers_replace = var.config_version # change -> replace
}

resource "local_file" "config" {
  content  = jsonencode({ service = random_pet.service.id, replicas = var.replicas })
  filename = "${path.module}/config.json"
}

resource "local_file" "firewall_ingress" {
  content  = jsonencode({ ingress_cidr = var.ingress_cidr })
  filename = "${path.module}/firewall_ingress.json"
}

resource "local_file" "firewall_admin" {
  content  = jsonencode({ admin_cidr = var.ingress_cidr })
  filename = "${path.module}/firewall_admin.json"
}
