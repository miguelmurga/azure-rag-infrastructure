# Get current public IP for admin access
data "http" "my_public_ip" {
  url = "https://api.ipify.org"
}

locals {
  admin_ip_cidr = "${chomp(data.http.my_public_ip.response_body)}/32"
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Generate random strings for passwords and keys
resource "random_password" "cosmosdb_password" {
  length  = 24
  special = true
}

resource "random_password" "chromadb_api_key" {
  length  = 32
  special = false
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

resource "random_string" "unique" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = true
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Generate SSH key if needed during deployment
resource "null_resource" "generate_ssh_key" {
  provisioner "local-exec" {
    command = <<-EOT
      if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
      fi
    EOT
  }
}

data "local_file" "ssh_public_key" {
  depends_on = [null_resource.generate_ssh_key]
  filename   = pathexpand("~/.ssh/id_rsa.pub")
}
