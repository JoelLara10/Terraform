variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "location" {
  type    = string
  default = "eastus"
}
variable "project" {
  type    = string
  default = "ineolz"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,9}$", var.project))
    error_message = "Usa entre 3 y 10 letras minusculas o digitos, iniciando con letra."
  }
}
variable "environment" {
  type    = string
  default = "lab"
}
variable "owner" {
  type    = string
  default = "Joel Lara"
}
variable "ssh_public_key_path" {
  description = "Ruta a la clave PUBLICA SSH de la laptop. Nunca la privada."
  type        = string
}
variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}
variable "entra_admin_object_id" {
  description = "Object ID de un usuario del tenant que administrara PostgreSQL."
  type        = string
}
variable "entra_admin_login" {
  description = "UPN del usuario administrador de Entra de PostgreSQL."
  type        = string
}
variable "vm_size" {
  type    = string
  default = "Standard_D2as_v4"
}
variable "postgres_sku" {
  type    = string
  default = "B_Standard_B1ms"
}
variable "app_service_sku" {
  description = "B1 soporta integracion VNet. F1 no implementa esta arquitectura."
  type        = string
  default     = "B1"
  validation {
    condition     = contains(["B1", "B2", "B3", "S1", "P0v3", "P1v3"], var.app_service_sku)
    error_message = "Selecciona un plan compatible con integracion VNet."
  }
}
variable "enable_vm_outbound" {
  description = "NAT explicito para instalar herramientas y acceder a servicios externos desde la VM sin IP publica."
  type        = bool
  default     = true
}

variable "postgres_location" {
  description = "Region para PostgreSQL. La politica sys.regionrestriction solo permite northcentralus, southcentralus, mexicocentral, eastus y eastus2. De esas, eastus, eastus2 y southcentralus rechazan el aprovisionamiento de Flexible Server para esta suscripcion, por lo que queda mexicocentral. El Private Endpoint permanece en var.location; Private Link entre regiones es compatible. Verifica con: az postgres flexible-server list-skus --location <region>."
  type        = string
  default     = "mexicocentral"
}
variable "postgres_version" {
  description = "Version de PostgreSQL compatible con la region y suscripcion."
  type        = string
  default     = "16"
  validation {
    condition     = contains(["14", "15", "16", "17"], var.postgres_version)
    error_message = "Usa una version admitida por AzureRM 4.81 y verifica su disponibilidad regional."
  }
}
