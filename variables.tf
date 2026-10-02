variable "length" {
    description = "Length of the random string"
    type = number
    default = 5
}

variable "aplication_name" {
    description = "Nombre de la aplicacion"
    type = string
    default = "Integradora"
}

variable "enviroment" {
    description = "Entorno donde se despliega"
    type = string
    default = "dev"
}

variable "enable_monitoring" {
    description = "Habilitar o deshabilitar el monitoreo"
    type = bool
    default = true
}

variable "regions" {
    description = "Regiones donde se desplegara"
    type = list(string)
    default = ["us-west-1", "us-east-1"]
}

variable "enviroment_tags" {
    description = "Etiquetas especificas para cada entorno"
    type = map(string)
    default = {
        dev = "Development"
        prd = "Production"
    }
}

variable "aplication_config" {
    description = "Configuracion de la aplicacion"
    type = object({
        version = string
        maintainer = string
        dependencies = list(string)
    })
    default = {
        version = "1.0.0"
        maintainer = "CarlosMategui"
        dependencies = ["nginx", "nodejs"]
    }
}

variable "allowed_networks" {
    description = "Lista de redes permitidas"
    type = set(string)
    default = ["10.0.0.0/8", "172.16.0.0/12"]
}