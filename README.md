# Azure RAG Infrastructure as Code

Este repositorio contiene la infraestructura como código (IaC) utilizando Terraform para desplegar una arquitectura de Retrieval Augmented Generation (RAG) en Azure.

## Arquitectura

La infraestructura despliega los siguientes componentes:

- **Azure Virtual Machine**: Ejecuta ChromaDB como vector database
- **Azure Cosmos DB MongoDB API**: Base de datos para almacenamiento de logs
- **Azure Key Vault**: Almacenamiento seguro de secretos
- **Redes y Seguridad**: VNet, NSG, DDoS Protection, etc.


## Requisitos Previos

- Terraform v1.0.0+
- Azure CLI
- Cuenta de Azure con permisos suficientes

## Estructura del Repositorio

```
azure-rag-infrastructure/
├── main.tf              # Configuración principal y recursos compartidos
├── variables.tf         # Definición de variables
├── outputs.tf           # Outputs del despliegue
├── network.tf           # Recursos de red
├── security.tf          # Recursos de seguridad
├── database.tf          # Recursos de base de datos
├── vm.tf                # Recursos de máquina virtual
├── providers.tf         # Configuración de providers
├── scripts/
│   └── setup_chromadb.sh # Script de configuración de ChromaDB
└── docs/
    └── images/
        └── architecture.png
```

## Variables Principales

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `location` | Región de Azure | "mexicocentral" |
| `resource_group_name` | Nombre del grupo de recursos | "rg-rag-infrastructure" |
| `admin_username` | Nombre de usuario para la VM | "adminuser" |
| `vm_size` | Tamaño de la VM para ChromaDB | "Standard_D4s_v3" |
| `vm_disk_size_gb` | Tamaño de disco para VM en GB | 100 |

## Uso

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/yourusername/azure-rag-infrastructure.git
   cd azure-rag-infrastructure
   ```

2. Inicializar Terraform:
   ```bash
   terraform init
   ```

3. Crear un plan de ejecución:
   ```bash
   terraform plan -out=tfplan
   ```

4. Aplicar la infraestructura:
   ```bash
   terraform apply tfplan
   ```

5. Destruir la infraestructura cuando ya no sea necesaria:
   ```bash
   terraform destroy
   ```

## Seguridad

La infraestructura se configura con las siguientes medidas de seguridad:

- Firewalls y NSGs para limitar el acceso a los recursos
- Conexiones cifradas con TLS
- Azure Key Vault para secretos
- Autenticación basada en tokens para ChromaDB
- Identidades administradas para accesos seguros
- Protección DDoS para la red

## Configuración de ChromaDB

ChromaDB se despliega como un contenedor en la VM de Azure y se configura con un API key generado automáticamente durante el despliegue. La VM se configura con un proxy NGINX que proporciona cifrado TLS.

## Notas

- Los secretos generados durante el despliegue se almacenan en Azure Key Vault
- La configuración permite acceso SSH solo desde la IP desde donde se ejecuta el despliegue
- El endpoint de ChromaDB está protegido con autenticación por token

## Contribuciones

Las contribuciones son bienvenidas. Por favor, abra un issue o pull request para cualquier mejora o corrección.

## Licencia

[MIT](LICENSE)
