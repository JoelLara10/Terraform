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