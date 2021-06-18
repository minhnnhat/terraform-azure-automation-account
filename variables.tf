variable "resource_group_name" {
  description = "Resource group name"
}

variable "location" {
  description = "Location of resource group"
}

variable "name" {
  description = "Automation account name"
}

variable "modules" {
  description = "Modules used in DSC"
  type        = map(any)
}

variable "vm_ids" {
  description = "Virtual machine id"
}

variable "credentials" {
  description = "Credentials used in DSC"
  type        = map(any)
}

variable "dscfiles" {
  description = "DSC files used in DSC"
  type        = map(any)
}