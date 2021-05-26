variable "modules" {
    type = map
}

variable "name" {
    description = "Name of automation account"
}

variable "rg_name" {
    description = "Name of resource group"
}

variable "rg_location" {
    description = "Location of resource group"
}

variable "vm_id" {
    description = "Virtual machine id"
}