# Example governance for Azure sandbox environments
This repo contains my PoC resources to build opinionated governance of sandbox environments in Azure.

## Goals
Here are goals and design decisions:
- Sandbox environment should be as open and flexible as possible
- All owners should be have identifiable resources
- Costs are strictly controlled with automated actions including stopping or even deleting resources when violating budgets
- Deployment of governance constructs fully automated via Terraform

## Policies
Tagging policies are designed to enforce proper tagging structure:
- Each tag is defined as separate policy definition rather than parametrized one. Reason is definition name is listed as part of error message (but parameters not) therefore it is more clear to users what is missing.
- Tags are required for Resource Groups only. Reasoning is that there are a lot of examples on the Internet that do not include tags making unexperienced users getting errors which is making their experience worse.
- Key tags from Resource Groups are forcefully copied to resources within Resource Group to make all resources searchable by tag without users being required to provide those.
- All definitions are bundled as initiative
- Policy definitions and assignments are done on Management Group scope. Reason is I would suggest against assigning policy on scope of subscription, rather use Management Group. This allows for sandbox users to be Owners of subscription and yet they cannot change this policy as they are not Owners on Management Group level. Note alternative would be to let users be Contributors, but that would encourage people to request powerful Service Principal accounts rather than using (and self-service assign RBAC for) Managed Identities with least privilege (eg. for Kubernetes, Databricks, Data Factory, apps etc.).

### Prepare Management Group
```bash
# Create Management Group
az account management-group create --name SandboxManagementGroup

# Assign subscriptions
az account management-group subscription add --name SandboxManagementGroup --subscription mySubscriptionName

# Get Management Group ID
export mg=$(az account management-group show --name SandboxManagementGroup --query id -o tsv)
```

### Deploy with Terraform

```bash
az login
az account set --subscription mySubscriptionName

cd policies
terraform init
terraform apply -auto-approve -var management-group-name=SandboxManagementGroup
# terraform destroy -auto-approve -var management-group-name=SandboxManagementGroup
```

### Testing policy effect
```bash
az group create -n test1-rg -l westeurope   # No tag - should fail
az group create -n test1-rg -l westeurope --tags owner=tomas@tomas.cz  # Tag costcenter missing
az group create -n test1-rg -l westeurope --tags owner=tomas@tomas.cz costlocation=S10  # OK

az network public-ip create -n ip1 -g test1-rg 
az network public-ip show -n ip1 -g test1-rg  --query tags # See tags got inherited from resource group

az group delete -n test1-rg -y --no-wait
```

## Cost management
In this setup we are using:
- Azure Functions (serverless) with PowerShell code to automate actions such as deleting resources or stopping VMs
- Action Groups definitions to react on budget milestones (will start Functions accordingly)
- Automate creation of budgets

Notes:
- Terraform currently does not support budgets as resource (you can track commit here: https://github.com/terraform-providers/terraform-provider-azurerm/pull/9201). As workaround I used ARM template deployed via Terraform for budget creation.
- I used PowerShell code in Functions to automate stopping and deleting resources because it was easiest and Functions automatically authenticate to Azure using Managed Identity
- Code in function reacts on single tag (tagName/tagValue) - you need to enhance if you need more complex matching
- As budget alert schema does not provide all details, I first read budget details by its ID to get its filter condition, parse it and use it as input for Function. Note again this PoC is written to parse single tagName/tagValue.
- Only budgetActionDelete and budgetActionStop are used in budgets. Functions deleteRgByTag and stopVmByRgTag are currently not used, but I plan to use it with more complex email alerts (give receiver ability to click button to stop/delete right away)
- Note how code is deployed to Azure Functions - if you want to change or create your own install local development environment in VS Code and package result as zip file. This gets uploaded by Terraform to storage account in Azure which is than used as source for code deployment.
- Actual budgets are defined as data structure in budgets variable as in example in budgets.tf file where amount is monthly value in USD, contact is email recepient, tagName and tagValue is owner and email in my case.

TBD:
- Provide richer user alerting experience such as email with buttons to automate or escalate
- Budget API seem to require start day which cannot be in a past - investigate how to automate this

### Deploy with Terraform
```bash
az login
az account set --subscription mySubscriptionName

# If code of automation functions is modified, recreate zip file - not require if you have not changed code
cd automationFunctions
zip -r ../budgets/automationFunctions.zip *

# Deploy
cd budgets
terraform init
terraform apply -auto-approve
# terraform destroy -auto-approve
```

# Testing budgets, alerts and automation

```bash
# Create two resource groups with the same tagging
az group create -n test2-rg -l westeurope --tags owner=tokubica@microsoft.com costlocation=S10 
az group create -n test3-rg -l westeurope --tags owner=tokubica@microsoft.com costlocation=S10

# Create one VM in each resource group
az vm create -n vm1 -g test2-rg --image UbuntuLTS --no-wait 
az vm create -n vm2 -g test3-rg --image UbuntuLTS --no-wait

# Check groups are there
az group list --tag owner=tokubica@microsoft.com -o table

# Check VMs are running - should be stopped when on 110% of budget (and deleted when on 150%)
az vm list --query "[?tags.owner=='tokubica@microsoft.com']" -d -o table
```

