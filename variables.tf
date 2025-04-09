variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "mexicocentral"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-rag-infrastructure"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "vm_size" {
  description = "Size of the VM for ChromaDB"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "vm_disk_size_gb" {
  description = "Disk size for VM in GB"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "RAG-Infrastructure"
  }
}
