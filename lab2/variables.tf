variable "project_name" {
    description = "Nombre del proyecto"
    type = string
    validation {
        condition = length(var.project_name) >= 5 && length(var.project_name) <= 20
        error_message = "El nombre del proyecto debe contener solo letras minusculas y tener 20 caracteres como maximo."
    }
}

variable "enviroment" {
    description = "Entorno de despliegue"
    type = string
    validation {
        condition = contains(["dev", "qa", "prod"], var.enviroment)
        error_message = "Los entornos validos son: dev, qa, prod"
    }
}

variable "location" {
    description = "Recursos de despliegue"
    type = string
    default = "mexicocentral"
}

variable "vnet_address_space" {
    description = "Address space de la vnet"
    type = string
    default = "10.0.0.0/16"
}

variable "tags" {
    description = "Tags para los recursos"
    type = map(string)
    default = "terraform"
}