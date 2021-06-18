#----------------
# Resource group
#----------------
locals {
  resource_group_name = var.resource_group_name
  location            = var.location
}
#---------------------------
# Create automation account
#---------------------------
resource "azurerm_automation_account" "az_aa" {
  resource_group_name = local.resource_group_name
  location            = local.location

  name     = var.name
  sku_name = "Basic"
}
#----------------
# Import modules
#----------------
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

resource "azurerm_template_deployment" "ComputerManagementDsc" {
  resource_group_name = local.resource_group_name

  name            = "ComputerManagementDsc_${substr(tostring(uuid()), 0, 8)}"
  deployment_mode = "Incremental"
  template_body   = file("${path.module}/modules/AutomationAccounts.module.json")

  parameters = {
    automationAccount = "${azurerm_automation_account.az_aa.name}"
    moduleName        = "ComputerManagementDsc"
    contentLink       = "https://www.powershellgallery.com/api/v2/package/ComputerManagementDsc/8.4.0"
    region            = "${local.location}"
  }

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}
#----------------
# Setup LCM
#----------------
resource "azurerm_virtual_machine_extension" "az_aa_ext" {
  name                       = "Microsoft.Powershell.DSC"
  for_each                   = var.vm_ids
  virtual_machine_id         = each.value
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
                    "RebootNodeIfNeeded": true,
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

resource "azurerm_automation_dsc_configuration" "az_aa_dscc_sql" {
  resource_group_name = local.resource_group_name
  location            = local.location

  for_each = var.dscfiles
  name     = each.key

  automation_account_name = azurerm_automation_account.az_aa.name


  content_embedded = file("${path.root}/${each.value}")
}