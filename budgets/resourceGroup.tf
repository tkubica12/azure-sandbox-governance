// Create resource groups for budgets and automation objects
resource "azurerm_resource_group" "budgets" {
  name     = "budgets-rg"
  location = "westeurope"
  tags = {
    costlocation = "A15"
    owner        = "tomas@tomas.cz"
  }
}