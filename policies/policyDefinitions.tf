// Define tagging policies for different tags (check policy rule)

// Deny creation of resource groups missing certain tags
resource "azurerm_policy_definition" "require-tag-owner-on-rg" {
  name                = "require-tag-owner-on-rg"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Require tag 'owner' on resource group"
  management_group_name = var.management-group-name


  metadata = <<METADATA
    {
    "version": "1.0.0",
    "category": "Custom"
    }

METADATA

  policy_rule = <<POLICY_RULE
    {   
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions/resourceGroups"
          },
          {
            "field": "tags['owner']",
            "exists": "false"
          }
        ]
      },
      "then": {
        "effect": "deny"
      }
    }
POLICY_RULE

}

resource "azurerm_policy_definition" "require-tag-costlocation-on-rg" {
  name                = "require-tag-costlocation-on-rg"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Require tag 'costlocation' on resource group"
  management_group_name = var.management-group-name


  metadata = <<METADATA
    {
    "version": "1.0.0",
    "category": "Custom"
    }

METADATA

  policy_rule = <<POLICY_RULE
    {   
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions/resourceGroups"
          },
          {
            "field": "tags['costlocation']",
            "exists": "false"
          }
        ]
      },
      "then": {
        "effect": "deny"
      }
    }
POLICY_RULE

}

// Inherit resource tags from Resource Group

resource "azurerm_policy_definition" "inherit-tag" {
  name                = "inherit-tag"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Inherit tag from resource group"
  management_group_name = var.management-group-name


  metadata = <<METADATA
    {
    "version": "1.0.0",
    "category": "Custom"
    }
METADATA

  parameters = <<PARAMETERS
    {
        "tagName": {
            "type": "String",
            "metadata": {
                "displayName": "Tag Name",
                "description": "Name of the tag, such as 'environment'"
            }
        }
    }
PARAMETERS

  policy_rule = <<POLICY_RULE
    {
        "if": {
            "allOf": [{
                    "field": "[concat('tags[', parameters('tagName'), ']')]",
                    "notEquals": "[resourceGroup().tags[parameters('tagName')]]"
                },
                {
                    "value": "[resourceGroup().tags[parameters('tagName')]]",
                    "notEquals": ""
                }
            ]
        },
        "then": {
            "effect": "modify",
            "details": {
                "roleDefinitionIds": [
                    "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
                ],
                "operations": [{
                    "operation": "addOrReplace",
                    "field": "[concat('tags[', parameters('tagName'), ']')]",
                    "value": "[resourceGroup().tags[parameters('tagName')]]"
                }]
            }
        }
    }
POLICY_RULE

}

// Combine individual policies into tagging initiative
resource "azurerm_policy_set_definition" "tagging-policy" {
  name                = "tagging-policy"
  policy_type         = "Custom"
  display_name        = "Tagging policy"
  management_group_name = var.management-group-name

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require-tag-owner-on-rg.id
    reference_id         = "require-owner"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require-tag-costlocation-on-rg.id
    reference_id         = "require-costlocation"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.inherit-tag.id
    reference_id         = "inherit-owner"
    parameter_values     = <<PARAMETERS
    {
    "tagName": {
        "value": "owner"
        }
    }
PARAMETERS
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.inherit-tag.id
    reference_id         = "inherit-costlocation"
    parameter_values     = <<PARAMETERS
    {
    "tagName": {
        "value": "costlocation"
        }
    }
PARAMETERS
  }

}
