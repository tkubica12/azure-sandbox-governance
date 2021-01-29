data "azurerm_management_group" "mg" {
  name = var.management-group-name
}


// Assign tagging iniciative on Management Group scope

resource "azurerm_policy_assignment" "sandbox-mg-tagging-initiative" {
  name                 = "enforce-tags"
  scope                = data.azurerm_management_group.mg.id
  policy_definition_id = azurerm_policy_set_definition.tagging-policy.id
  description          = "Do not allow creation of resources not compliant with required tags"
  display_name         = "Enforce tagging on resources"
  location             = "westeurope"
  identity { type = "SystemAssigned" }
}
