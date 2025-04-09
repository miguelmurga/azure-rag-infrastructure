# Network Interface for VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-chromadb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }

  tags = var.tags
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# VM for ChromaDB
resource "azurerm_linux_virtual_machine" "vm_chromadb" {
  name                  = "vm-chromadb"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  # Use managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm_identity.id]
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.local_file.ssh_public_key.content
  }

  os_disk {
    name                 = "osdisk-chromadb"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.vm_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Archivo cloud-init para configuración inicial
  custom_data = filebase64("${path.module}/scripts/setup_chromadb.sh")

  tags = var.tags
}

# Script para reemplazar variables en el script remoto
resource "null_resource" "configure_vm" {
  depends_on = [azurerm_linux_virtual_machine.vm_chromadb]

  triggers = {
    vm_id = azurerm_linux_virtual_machine.vm_chromadb.id
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file("~/.ssh/id_rsa")
    host        = azurerm_public_ip.vm_ip.ip_address
  }

  # Transferir script con variables actualizadas
  provisioner "file" {
    content = templatefile("${path.module}/scripts/setup_chromadb.sh", {
      CHROMADB_API_KEY = random_password.chromadb_api_key.result,
      username         = var.admin_username
    })
    destination = "/tmp/setup_chromadb.sh"
  }

  # Ejecutar script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_chromadb.sh",
      "sudo /tmp/setup_chromadb.sh",
      "rm /tmp/setup_chromadb.sh"
    ]
  }
}

# Script to update Key Vault network ACLs with VM's public IP
resource "null_resource" "update_keyvault_acls" {
  depends_on = [azurerm_linux_virtual_machine.vm_chromadb]

  triggers = {
    vm_ip = azurerm_public_ip.vm_ip.ip_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      az keyvault network-rule add \
        --name ${azurerm_key_vault.kv.name} \
        --resource-group ${azurerm_resource_group.rg.name} \
        --ip-address ${azurerm_public_ip.vm_ip.ip_address}/32
    EOT
  }
}

# Script to update CosmosDB firewall with VM's public IP
resource "null_resource" "update_cosmosdb_firewall" {
  depends_on = [azurerm_linux_virtual_machine.vm_chromadb]

  triggers = {
    vm_ip = azurerm_public_ip.vm_ip.ip_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      az cosmosdb update --name ${azurerm_cosmosdb_account.cosmosdb.name} \
        --resource-group ${azurerm_resource_group.rg.name} \
        --ip-range-filter "${local.admin_ip_cidr},${azurerm_public_ip.vm_ip.ip_address}"
    EOT
  }
}
