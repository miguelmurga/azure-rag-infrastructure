# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "kv-rag-secrets${random_string.unique.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = false
  
  tags = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [local.admin_ip_cidr]
  }
}

# Key Vault Access Policy for current user
resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
}

# User Assigned Identity for VM
resource "azurerm_user_assigned_identity" "vm_identity" {
  name                = "id-vm-chromadb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Key Vault Access Policy for VM's managed identity
resource "azurerm_key_vault_access_policy" "vm" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.vm_identity.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "ENCRYPTED-CREDENTIAL-SECRET"
  value        = random_password.jwt_secret.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.admin]
}

resource "azurerm_key_vault_secret" "chromadb_api_key" {
  name         = "CHROMADB-API-KEY"
  value        = random_password.chromadb_api_key.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.admin]
}
