locals {
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_automation_account" "az_aa" {
  location            = local.location
  resource_group_name = local.resource_group_name

  name     = var.name
  sku_name = "Basic"
}

resource "azurerm_automation_module" "az_aa_module" {
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.az_aa.name

  for_each = var.modules
  name     = each.key

  module_link {
    uri = each.value
  }

  timeouts {
    create = "15m"
  }
}

resource "azurerm_virtual_machine_extension" "az_aa_ext" {
  name                       = "Microsoft.Powershell.DSC"
  virtual_machine_id         = var.vm_id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.77"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS_JSON
            {
                "configurationArguments": {
                    "RegistrationUrl" : "${azurerm_automation_account.az_aa.dsc_server_endpoint}",
                    "ConfigurationMode": "ApplyAndAutoCorrect",
                    "RefreshFrequencyMins": 30,
                    "ConfigurationModeFrequencyMins": 15,
                    "RebootNodeIfNeeded": false,
                    "ActionAfterReboot": "continueConfiguration",
                    "AllowModuleOverwrite": false
    
                }
            }
SETTINGS_JSON

  protected_settings = <<PROTECTED_SETTINGS_JSON
        {
            "configurationArguments": {
                    "RegistrationKey": {
                        "userName": "NOT_USED",
                        "Password": "${azurerm_automation_account.az_aa.dsc_primary_access_key}"
                    }
            }
        }
PROTECTED_SETTINGS_JSON
}

resource "azurerm_automation_credential" "az_aa_cred" {
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.az_aa.name

  for_each = var.credentials
  name     = each.value.cred_name
  username = each.value.cred_user
  password = each.value.cred_pass
}