# AKS Infrastructure Deployment Documentation

This documentation describes the steps to deploy an Azure Kubernetes Service (AKS) infrastructure with additional resources using Bicep, PowerShell scripts, and Azure Pipelines. The resources include Application Gateway, Virtual Network, Bastion Host, and Azure Container Registry (ACR).

## Prerequisites

Ensure the following prerequisites are met before starting:

1. **Azure CLI**: Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and authenticate using your service principal credentials.

2. **Azure PowerShell Module**: Install the [Azure PowerShell Module](https://learn.microsoft.com/en-us/powershell/azure/new-azureps-module-az).

3. **Service Principal**: Create an Azure Service Principal with sufficient permissions and note down the following credentials:
   - `App ID`
   - `Client Secret`
   - `Tenant ID`

4. **Azure Key Vault**: Ensure access to an Azure Key Vault to securely store sensitive information.

---

## Repository Structure

This repository includes:

- **`main.bicep`**: Defines AKS and supporting infrastructure resources.
- **`main.bicepparam`**: Parameter file for the Bicep template, specifying required deployment values.
- **`script.ps1`**: PowerShell script for initiating and managing the deployment.
- **`azure-pipelines.yml`**: Azure DevOps pipeline file to automate the deployment.

---

## Step-by-Step Guide

### 1. Configuring `main.bicepparam`

The `main.bicepparam` file is used to pass required parameters to the `main.bicep` template. Populate it as shown below:

```bicep
// main.bicepparam
param currentUserObjectId string = '<your_user_object_id>'
param password string = '<your_password>'
```

- Replace `<your_user_object_id>` with the Object ID of the user or service principal that will deploy the resources.
- Replace `<your_password>` with the password or any other required secure string.

### 2. Running the PowerShell Script (`script.ps1`)

The `script.ps1` script facilitates deploying the infrastructure in a resource group.

#### **Parameters**

The script accepts the following parameters:

- `argocdAppId`: Service Principal App ID for authentication.
- `argocdSecret`: Service Principal secret for authentication.
- `argocdTenant`: Tenant ID for the Azure subscription.

#### **Script Execution**

```powershell
# Open PowerShell and run the following command:

param(
    [Parameter(Mandatory=$true)][string]$argocdAppId,
    [Parameter(Mandatory=$true)][string]$argocdSecret,
    [Parameter(Mandatory=$true)][string]$argocdTenant
)

$resourceGroup = "rg-argocd"
$location = "East US"

# Log in with service principal
az login --service-principal -u $argocdAppId -p $argocdSecret --tenant $argocdTenant

# Create the resource group if it doesn’t exist
az group create --name $resourceGroup --location $location

# Deploy the Bicep template
az deployment group create --resource-group $resourceGroup `
    --mode Complete `
    --name argocd-deployment `
    --template-file .\main.bicep `
    --parameters .\main.bicepparam
```

---

### 3. Setting Up and Running Azure Pipeline (`azure-pipelines.yml`)

The Azure pipeline file automates the deployment of AKS infrastructure by running the PowerShell script with parameters stored in Azure Key Vault.

#### Pipeline Configuration

The `azure-pipelines.yml` file contains the pipeline setup for Azure DevOps.

- **Service Connection**: Set up the service connection in Azure DevOps for your Azure subscription, named as `argocd`.
- **Key Vault Secrets**: Ensure the Key Vault has the following secrets:
  - `argocdAppId`: Service Principal Application ID.
  - `argocdSecret`: Service Principal Client Secret.
  - `argocdTenant`: Azure Tenant ID.

#### Pipeline YAML

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  resourceGroupName: 'rg-argocd'
  location: 'East US'
  templateFile: 'main.bicep'
  parametersFile: 'main.bicepparam'

steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'argocd'
      KeyVaultName: 'argocd'
      SecretsFilter: '*'
      RunAsPreJob: true

  - task: AzureCLI@2
    inputs:
      azureSubscription: 'argocd'
      scriptType: 'ps'
      scriptLocation: 'inlineScript'
      inlineScript: |
        param(
          [Parameter(Mandatory=$true)][string]$argocdAppId,
          [Parameter(Mandatory=$true)][string]$argocdSecret,
          [Parameter(Mandatory=$true)][string]$argocdTenant
        )

        $resourceGroup = "$(resourceGroupName)"
        $location = "$(location)"
        
        az login --service-principal -u $argocdAppId -p $argocdSecret --tenant $argocdTenant
        az group create --name $resourceGroup --location $location

        az deployment group create --resource-group $resourceGroup `
          --mode Complete `
          --name argocd-deployment `
          --template-file $(templateFile) `
          --parameters $(parametersFile)
```

---

## Resources Created

The deployment creates the following resources:

- **AKS Cluster**: Azure Kubernetes Service for managing containerized workloads.
- **Application Gateway**: Load balancer for web traffic.
- **Virtual Network**: A VNet with subnets for resources.
- **Bastion Host**: Secure access to VMs within the network.
- **Azure Container Registry (ACR)**: Storage for container images.
- **Private DNS Zone**: For managing DNS within the network.

---

## Outputs

After a successful deployment, the pipeline outputs essential information, including:

- **ACR URL**: Displayed in the following format: `<acr-name>.azurecr.io`

