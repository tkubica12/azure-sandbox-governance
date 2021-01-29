// Get authentication token for Function Apps
data "azurerm_function_app_host_keys" "budget" {
  name                = azurerm_function_app.budgets.name
  resource_group_name = azurerm_function_app.budgets.resource_group_name
}

// Create Action Groups for stop and delete
resource "azurerm_monitor_action_group" "stop" {
  name                = "budgetReactionStop"
  resource_group_name = azurerm_resource_group.budgets.name
  short_name          = "budgetStop"

  azure_function_receiver {
    name                     = "function"
    function_app_resource_id = azurerm_function_app.budgets.id
    function_name            = "budgetActionStop"
    http_trigger_url         = "https://${azurerm_function_app.budgets.name}.azurewebsites.net/api/budgetActionStop?code=${data.azurerm_function_app_host_keys.budget.master_key}"
    use_common_alert_schema  = false
  }
}

resource "azurerm_monitor_action_group" "delete" {
  name                = "budgetReactionDelete"
  resource_group_name = azurerm_resource_group.budgets.name
  short_name          = "budgetDelete"

  azure_function_receiver {
    name                     = "function"
    function_app_resource_id = azurerm_function_app.budgets.id
    function_name            = "budgetActionDelete"
    http_trigger_url         = "https://${azurerm_function_app.budgets.name}.azurewebsites.net/api/budgetActionDelete?code=${data.azurerm_function_app_host_keys.budget.master_key}"
    use_common_alert_schema  = false
  }
}
