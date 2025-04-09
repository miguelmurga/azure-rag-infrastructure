# Arquitectura de la Infraestructura RAG en Azure

Este documento describe la arquitectura de la infraestructura de Retrieval Augmented Generation (RAG) en Azure.

## Visión General

La arquitectura implementa una infraestructura escalable y segura para sistemas RAG, aprovechando servicios gestionados de Azure combinados con ChromaDB para el almacenamiento de vectores.

![Diagrama de Arquitectura](images/architecture.png)

## Componentes Principales

### 1. ChromaDB en VM de Azure

- **Propósito**: Almacenamiento de vectores para la recuperación semántica
- **Implementación**: VM Linux con ChromaDB en contenedor
- **Seguridad**: 
  - Acceso mediante token de API
  - HTTPS con TLS
  - Firewall para restringir acceso
  - Sistema operativo endurecido

### 2. Azure Cosmos DB (API MongoDB)

- **Propósito**: Almacenamiento de logs y telemetría del sistema RAG
- **Características**:
  - Modo serverless para optimizar costos
  - Índices optimizados para consultas
  - Esquema flexible para datos de logs
  - TTL (Time-to-Live) configurable para gestión de datos

### 3. Azure Key Vault

- **Propósito**: Almacenamiento seguro de secretos y claves
- **Secretos**:
  - API Key para ChromaDB
  - Cadena de conexión para CosmosDB
  - Otros secretos de aplicación

### 4. Redes y Seguridad

- **Virtual Network**: Red aislada para todos los recursos
- **Network Security Group**: Control de acceso a nivel de red
- **DDoS Protection**: Plan de protección contra ataques DDoS
- **Firewall Rules**: Acceso restringido por IP

## Flujo de Datos

1. **Operaciones de Embedding y Búsqueda**:
   - Las aplicaciones cliente se conectan a ChromaDB a través de HTTPS
   - Autenticación mediante token de API
   - Las colecciones de vectores se almacenan persistentemente en la VM

2. **Logging y Monitoreo**:
   - Los eventos y métricas se registran en Cosmos DB
   - Esquema optimizado para análisis de rendimiento y uso

## Consideraciones de Seguridad

- **Acceso por IP**: Restricción de acceso a recursos por direcciones IP específicas
- **Seguridad en VM**:
  - Fail2ban para prevención de ataques de fuerza bruta
  - Actualizaciones automáticas de seguridad
  - Auditoría de seguridad
  - SSH endurecido con autenticación por clave
  - Escaneos programados con rkhunter y chkrootkit

- **Seguridad en Datos**:
  - Cifrado en reposo para todos los datos
  - Cifrado en tránsito con HTTPS/TLS
  - Separación de credenciales en Key Vault

## Escalabilidad

- **ChromaDB**: Escalable verticalmente ajustando el tamaño de la VM
- **Cosmos DB**: Escalable automáticamente en modo serverless
- **Redes**: Estructura de subred que permite crecimiento

## Costos

Los principales componentes que afectan al costo son:

- **VM de Azure**: Costo fijo basado en el tamaño seleccionado
- **Cosmos DB**: Costo variable basado en el almacenamiento y operaciones
- **Key Vault**: Costo basado en operaciones de secretos
- **Almacenamiento**: Costo basado en GB almacenados y operaciones

La configuración serverless de Cosmos DB optimiza costos al pagar solo por lo usado.

## Monitoreo y Mantenimiento

- **Logs del Sistema**: Almacenados en la VM y accesibles mediante SSH
- **Logs de Aplicación**: Almacenados en Cosmos DB
- **Actualizaciones**: 
  - SO: Configurado para actualizaciones automáticas de seguridad
  - ChromaDB: Requiere actualización manual cuando hay nuevas versiones