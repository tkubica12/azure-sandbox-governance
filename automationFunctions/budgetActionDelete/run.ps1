using namespace System.Net

param($Request, $TriggerMetadata)

$SubscriptionId = $Request.Body.data.SubscriptionId
$BudgetName = $Request.Body.data.BudgetName

$getBudgetParams = @{
    ResourceProviderName = 'Microsoft.Consumption'
    ResourceType         = 'budgets'
    SubscriptionId       = $SubscriptionId
    Name                 = $BudgetName
    ApiVersion           = '2019-10-01'
    Method               = 'GET'
}

$budget = (Invoke-AzRestMethod @getBudgetParams).Content | ConvertFrom-Json

$tagName = $budget.properties.filter.tags.name
$tagValue = $budget.properties.filter.tags.values[0]

Write-Host "Removing Resource Groups with tags $tagName = $tagValue"
$result = Get-AzResourceGroup -Tag @{$tagName=$tagValue} | Remove-AzResourceGroup -Force -AsJob 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })
