output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm_ip.ip_address
}

output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.cosmosdb.endpoint
}

output "chromadb_api_endpoint" {
  value = "https://${azurerm_public_ip.vm_ip.ip_address}/api/v1"
}

output "chromadb_api_key" {
  value     = random_password.chromadb_api_key.result
  sensitive = true
}

output "cosmosdb_connection_string" {
  value     = "Revisar en Azure Portal o ejecutar: az cosmosdb keys list --type connection-strings --name ${azurerm_cosmosdb_account.cosmosdb.name} --resource-group ${azurerm_resource_group.rg.name}"
  sensitive = true
}

output "postman_instructions" {
  value = <<EOT
=== POSTMAN TESTING INSTRUCTIONS ===

1. ChromaDB Testing:
   URL: https://${azurerm_public_ip.vm_ip.ip_address}/api/v1
   Headers:
   - Content-Type: application/json
   - X-Chroma-Token: [Obtener de la salida sensible chromadb_api_key]
   
   Sample Query (Create Collection):
   POST /collections
   {
     "name": "test_collection",
     "metadata": { "description": "Test collection" }
   }

2. CosmosDB MongoDB API Testing:
   Obtener la cadena de conexión del Azure Portal
   Database: ${azurerm_cosmosdb_mongo_database.logs_db.name}
   Collection: ${azurerm_cosmosdb_mongo_collection.logs_collection.name}
EOT
}
