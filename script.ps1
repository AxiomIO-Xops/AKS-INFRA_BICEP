param(
    [Parameter(Mandatory=$true)][string]$argocdAppId,
    [Parameter(Mandatory=$true)][string]$argocdSecret,
    [Parameter(Mandatory=$true)][string]$argocdTenant
)

$resourceGroup = "rg-argocd"
$location = "East US"


az login --service-principal -u $argocdAppId -p $argocdSecret --tenant $argocdTenant

az group create --name $resourceGroup --location $location

# wait for connection to be ready
Start-Sleep -Seconds 5

az deployment group create --resource-group $resourceGroup `
    --mode Complete `
    --name argocd `
    --template-file .\main.bicep `
    --parameters .\main.bicepparam

