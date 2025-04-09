# Guía de Uso - Azure RAG Infrastructure

Esta guía explica cómo utilizar los componentes desplegados por esta infraestructura para implementar soluciones RAG (Retrieval Augmented Generation).

## Componentes Disponibles

Después del despliegue exitoso, tendrás acceso a:

1. **ChromaDB**: Una base de datos vectorial para almacenar y buscar embeddings
2. **Cosmos DB (MongoDB API)**: Una base de datos para almacenar logs y metadata
3. **Key Vault**: Para acceder a secretos y credenciales

## Conectar a ChromaDB

### Desde Python

Puedes conectarte a ChromaDB desde Python utilizando el cliente oficial:

```python
import chromadb
from chromadb.config import Settings

# Usar los valores de la salida de Terraform
CHROMA_API_ENDPOINT = "https://your-vm-ip/api/v1"
CHROMA_API_KEY = "your-api-key"  # Valor sensible de Terraform output

# Configurar el cliente
client = chromadb.HttpClient(
    host=CHROMA_API_ENDPOINT,
    ssl=True,
    headers={"X-Chroma-Token": CHROMA_API_KEY}
)

# Crear una colección
collection = client.create_collection(name="my_collection")

# Añadir documentos con embeddings
collection.add(
    documents=["Documento 1", "Documento 2"],
    metadatas=[{"source": "fuente1"}, {"source": "fuente2"}],
    ids=["id1", "id2"]
)

# Consultar documentos similares
results = collection.query(
    query_texts=["consulta de ejemplo"],
    n_results=2
)
```

### Desde Node.js

```javascript
import { ChromaClient } from 'chromadb';

// Usar los valores de la salida de Terraform
const CHROMA_API_ENDPOINT = "https://your-vm-ip/api/v1";
const CHROMA_API_KEY = "your-api-key"; // Valor sensible de Terraform output

// Configurar el cliente
const client = new ChromaClient({
  path: CHROMA_API_ENDPOINT,
  fetchOptions: {
    headers: {
      'X-Chroma-Token': CHROMA_API_KEY
    }
  }
});

async function main() {
  // Crear una colección
  const collection = await client.createCollection({
    name: "my_collection"
  });
  
  // Añadir documentos
  await collection.add({
    ids: ["id1", "id2"],
    documents: ["Documento 1", "Documento 2"],
    metadatas: [{"source": "fuente1"}, {"source": "fuente2"}]
  });
  
  // Consultar documentos similares
  const results = await collection.query({
    queryTexts: ["consulta de ejemplo"],
    nResults: 2
  });
  
  console.log(results);
}

main();
```

## Conectar a Cosmos DB (MongoDB API)

### Desde Python

```python
from pymongo import MongoClient

# Usar la cadena de conexión desde Terraform output
connection_string = "your-cosmosdb-connection-string"
client = MongoClient(connection_string)

# Conectar a la base de datos
db = client["rag-logs-db"]
collection = db["rag-logs-collection"]

# Insertar un log
log_entry = {
    "timestamp": "2023-07-18T15:30:45Z",
    "session": {
        "session_id": "abc123",
        "user_id": "user456"
    },
    "llm": {
        "model_used": "gpt-4",
        "tokens": 1250
    },
    "rag": {
        "retriever_type": "semantic",
        "documents_retrieved": 3,
        "query": "¿Cómo funciona RAG?"
    },
    "performance": {
        "retrieval_time_ms": 120,
        "generation_time_ms": 2500
    }
}

result = collection.insert_one(log_entry)
print(f"Inserted document with ID: {result.inserted_id}")

# Consultar logs
recent_logs = collection.find({"session.user_id": "user456"}).limit(10)
for log in recent_logs:
    print(log)
```

### Desde Node.js

```javascript
const { MongoClient } = require('mongodb');

// Usar la cadena de conexión desde Terraform output
const connectionString = "your-cosmosdb-connection-string";
const client = new MongoClient(connectionString);

async function main() {
  try {
    await client.connect();
    console.log("Connected to Cosmos DB");
    
    const database = client.db("rag-logs-db");
    const collection = database.collection("rag-logs-collection");
    
    // Insertar un log
    const logEntry = {
      timestamp: new Date().toISOString(),
      session: {
        session_id: "abc123",
        user_id: "user456"
      },
      llm: {
        model_used: "gpt-4",
        tokens: 1250
      },
      rag: {
        retriever_type: "semantic",
        documents_retrieved: 3,
        query: "¿Cómo funciona RAG?"
      },
      performance: {
        retrieval_time_ms: 120,
        generation_time_ms: 2500
      }
    };
    
    const result = await collection.insertOne(logEntry);
    console.log(`Inserted document with ID: ${result.insertedId}`);
    
    // Consultar logs
    const recentLogs = await collection.find({
      "session.user_id": "user456"
    }).limit(10).toArray();
    
    console.log(recentLogs);
  } finally {
    await client.close();
  }
}

main().catch(console.error);
```

## Probar con Postman

### Probar ChromaDB

1. Crear colección:
   - Método: POST
   - URL: `https://<vm_public_ip>/api/v1/collections`
   - Headers:
     - Content-Type: application/json
     - X-Chroma-Token: `<chromadb_api_key>`
   - Body:
     ```json
     {
       "name": "test_collection",
       "metadata": { "description": "Test collection" }
     }
     ```

2. Listar colecciones:
   - Método: GET
   - URL: `https://<vm_public_ip>/api/v1/collections`
   - Headers:
     - X-Chroma-Token: `<chromadb_api_key>`

### Probar Cosmos DB

Al usar MongoDB API, puedes conectar con cualquier herramienta compatible con MongoDB:

1. Configurar la conexión:
   - Connection String: `<cosmosdb_connection_string>`
   - Database: `rag-logs-db`
   - Collection: `rag-logs-collection`

2. Probar inserción:
   ```json
   {
     "message": "Test log entry",
     "timestamp": "2023-07-18T12:00:00Z"
   }
   ```

## Recomendaciones de Seguridad

1. Rotar periódicamente las claves API y secretos
2. Limitar el acceso por IP a los servicios
3. Monitorear los logs para detectar accesos no autorizados
4. Realizar backups periódicos de los datos de ChromaDB y CosmosDB