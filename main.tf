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
    length = 16
    special = true
}