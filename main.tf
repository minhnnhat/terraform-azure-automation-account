resource "azurerm_automation_account" "az_aa" {
    location            = var.rg_location
    resource_group_name = var.rg_name

    name                = var.name
    
    sku_name            = "Basic"
}

resource "azurerm_automation_module" "az_aa_module" {
    resource_group_name     = var.rg_name
    automation_account_name = azurerm_automation_account.az_aa.name

    for_each                = var.modules
    name                    = each.key

    module_link {
        uri = each.value
    }
}

resource "azurerm_virtual_machine_extension" "az_aa_ext" {
    name                 = "Microsoft.Powershell.DSC"
    virtual_machine_id   = var.vm_id
    publisher            = "Microsoft.Powershell"
    type                 = "DSC"
    type_handler_version = "2.77"
    auto_upgrade_minor_version = true
    settings = <<SETTINGS_JSON
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