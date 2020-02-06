
<#
Follows:
https://github.com/dkmiller/tidbits/blob/master/2020/2020-01-14_flask/Deploy.ps1
#>

param(
    [switch]$Login,
    [switch]$NoDeploy
)

$Json = Get-Content $PSScriptRoot/config.json | ConvertFrom-Json

$ResourceGroup = $Json.resource_group
$Subscription = $Json.subscription_id

if ($Login) {
    Write-Host 'Logging in...'
    az login    
}

Write-Host 'Setting Azure subscription...'
az account set --subscription $Subscription

if (!$NoDeploy) {
    Write-Host 'Deploying Azure resources...'
    az group deployment create `
      --name 'aml-object-recognition-pipeline' `
      --resource-group $ResourceGroup `
      --template-file "$PSScriptRoot/arm/template.json" `
      --parameters "@$PSScriptRoot/arm/parameters.json"    
}

$Parameters = Get-Content $PSScriptRoot/arm/parameters.json | ConvertFrom-Json

Write-Host 'Retrieving cognitive service key...'
$Keys = az cognitiveservices account keys list `
    --name $Parameters.parameters.name.value `
    -g $ResourceGroup | ConvertFrom-Json


Write-Host 'Setting environment variables...'
$env:COGNITIVE_SERVICES_API_KEY = $Keys.key1
$env:AZURE_REGION = $Parameters.parameters.location.value

python $PSScriptRoot\object-recognition-pipeline.py
