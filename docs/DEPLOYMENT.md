# Guía de Despliegue - Azure RAG Infrastructure

Esta guía explica el proceso de despliegue de la infraestructura RAG en Azure utilizando Terraform.

## Requisitos Previos

1. **Azure CLI**: Instalar y configurar [Azure CLI](https://docs.microsoft.com/es-es/cli/azure/install-azure-cli)
2. **Terraform**: Instalar [Terraform](https://www.terraform.io/downloads.html) v1.0.0 o superior
3. **Cuenta de Azure**: Tener una cuenta de Azure con permisos de Contributor o Owner
4. **SSH Key**: Tener una clave SSH configurada (el despliegue generará una si no existe)

## Pasos de Despliegue

### 1. Iniciar sesión en Azure

```bash
az login
```

### 2. Seleccionar la suscripción correcta (si tienes varias)

```bash
az account set --subscription "Mi Suscripción"
```

### 3. Clonar el repositorio

```bash
git clone https://github.com/yourusername/azure-rag-infrastructure.git
cd azure-rag-infrastructure
```

### 4. Inicializar Terraform

```bash
terraform init
```

### 5. Personalizar variables (opcional)

Crea un archivo `terraform.tfvars` para personalizar variables:

```hcl
location = "eastus2"
resource_group_name = "rg-my-rag-infra"
vm_size = "Standard_D4s_v3"
admin_username = "adminuser"
```

### 6. Validar la configuración

```bash
terraform validate
```

### 7. Crear un plan de ejecución

```bash
terraform plan -out=tfplan
```

### 8. Aplicar el despliegue

```bash
terraform apply tfplan
```

El despliegue tomará aproximadamente 10-15 minutos.

### 9. Verificar los Outputs

Después del despliegue, Terraform mostrará los outputs con información importante:

- `vm_public_ip`: Dirección IP pública de la VM
- `chromadb_api_endpoint`: Endpoint para conectar a ChromaDB
- `cosmosdb_endpoint`: Endpoint para conectar a CosmosDB

Para ver los outputs después del despliegue:

```bash
terraform output
```

Para ver los valores sensibles:

```bash
terraform output chromadb_api_key
terraform output cosmosdb_connection_string
```

## Configuración Post-Despliegue

### Actualizar Certificados SSL

Por defecto, se genera un certificado autofirmado. Para usar Let's Encrypt:

1. Configurar un nombre DNS para la IP pública de la VM
2. Conectar por SSH a la VM:
   ```bash
   ssh adminuser@<vm_public_ip>
   ```
3. Ejecutar Certbot:
   ```bash
   sudo certbot --nginx -d mydomain.com
   ```

### Actualizar Firewalls

Inicialmente, los firewalls están configurados para permitir acceso desde la IP utilizada durante el despliegue. Para añadir más IPs:

```bash
az keyvault network-rule add --name <keyvault_name> --resource-group <resource_group_name> --ip-address <new_ip>/32

az cosmosdb update --name <cosmosdb_name> --resource-group <resource_group_name> --ip-range-filter "<existing_ips>,<new_ip>"
```

## Destruir la Infraestructura

Cuando ya no necesites los recursos:

```bash
terraform destroy
```

## Solución de Problemas

### Error de conexión SSH después del despliegue

- **Problema**: No es posible conectarse por SSH a la VM
- **Solución**: Verifica que tu IP pública actual coincide con la registrada en el NSG

### Error al iniciar ChromaDB

- **Problema**: El servicio ChromaDB no responde
- **Solución**: Verificar los logs del contenedor:
  ```bash
  ssh adminuser@<vm_public_ip>
  cd ~/
  podman logs chromadb
  ```