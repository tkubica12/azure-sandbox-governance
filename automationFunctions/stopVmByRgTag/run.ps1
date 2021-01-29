using namespace System.Net

param($Request, $TriggerMetadata)

$tagName = $Request.Query.tagName
$tagValue = $Request.Query.tagValue

if ($tagName -and $tagValue) {
    Write-Host "Stopping VMs in Resource Groups with tags $tagName = $tagValue"
    $result = Get-AzResourceGroup -Tag @{$tagName=$tagValue} | Get-AzVM | Stop-AzVM -Force -AsJob
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result
    })
} else {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "tagName and tagValue must be set"
    })
}
