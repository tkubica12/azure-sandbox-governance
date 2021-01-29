using namespace System.Net

param($Request, $TriggerMetadata)

$tagName = $Request.Query.tagName
$tagValue = $Request.Query.tagValue

if ($tagName -and $tagValue) {
    Write-Host "Removing Resource Groups with tags $tagName = $tagValue"
    $result = Get-AzResourceGroup -Tag @{$tagName=$tagValue} | Remove-AzResourceGroup -Force -AsJob 
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
