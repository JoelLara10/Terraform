terraform {
    required_providers {
        random = {
            source = "hashicorp/random"
            version = "3.1.0"
        }
    }
    required_version = ">= 1.0"
}

resource "random_string" "suffix" {
    length = var.length
    special = true
}

locals {
    unique_name = "${var.aplication_name}-${var.enviroment}-${random_string.suffix.result}"
}