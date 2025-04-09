# CosmosDB Account con configuración compatible
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmosdb-rag-logs${random_string.unique.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  
  # Capacidades compatibles para MongoDB
  capabilities {
    name = "EnableMongo"
  }
  
  # MongoDB versión compatible
  capabilities {
    name = "MongoDBv3.4"
  }
  
  capabilities {
    name = "mongoEnableDocLevelTTL"
  }
  
  # Agregar capacidades avanzadas compatibles
  capabilities {
    name = "EnableMongoRetryableWrites"
  }
  
  # Soporte para transacciones de varios documentos
  capabilities {
    name = "DisableRateLimitingResponses"
  }
  
  # Mantener modo Serverless
  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  ip_range_filter = local.admin_ip_cidr
  
  tags = var.tags
}

# CosmosDB Database
resource "azurerm_cosmosdb_mongo_database" "logs_db" {
  name                = "rag-logs-db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  # No se especifica throughput en modo Serverless
}

# CosmosDB Collection for logs
resource "azurerm_cosmosdb_mongo_collection" "logs_collection" {
  name                = "rag-logs-collection"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_mongo_database.logs_db.name
  # No se especifica throughput en modo Serverless
  
  # Índices para consultas eficientes
  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys   = ["timestamp"]
    unique = false
  }

  index {
    keys   = ["session.session_id"]
    unique = false
  }

  index {
    keys   = ["session.user_id"]
    unique = false
  }
  
  # Índices adicionales para mejorar el rendimiento
  index {
    keys = ["llm.model_used"]
    unique = false
  }
  
  index {
    keys = ["rag.retriever_type"]
    unique = false
  }
  
  # Configuración de caducidad automática de documentos (TTL)
  # ttl_seconds = 2592000  # 30 días - Descomentar si se necesita
}
