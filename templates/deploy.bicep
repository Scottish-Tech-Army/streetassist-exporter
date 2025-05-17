// Parameters
@description('Name of the Azure Key Vault')
param keyVaultName string

@description('Globally unique name for the Container Registry')
param containerRegistryName string

@description('SQL Server admin username')
param sqlAdminUsername string = 'adminuser'

@description('SQL Server admin password')
@secure()
param sqlAdminPassword string = newGuid() // Random string

@description('SQL Server name (automatically generated if not provided)')
param sqlServerName string = 'sqlserver${uniqueString(resourceGroup().id)}'

@description('Name of the Container Apps Environment (managed environment).')
param containerAppEnvName string = 'exporterAppsEnv'

@description('Name of the Container Apps Job.')
param containerAppJobName string = 'exporter'

@description('Full image name including tag')
param containerImage string = '${containerRegistryName}.azurecr.io/exporter:latest'

@description('Registry URL')
param registryUrl string = '${containerRegistryName}.azurecr.io'

@description('Cron schedule for running the job - once per day at midnight')
param scheduleCron string = '0 0 * * *'

@description('Name of the storage account')
param storageAccountName string

@description('Blob storage container')
param blobContainerName string = 'csvdata'

// end

// Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    // For simplicity, we are not assigning any access policies in this example.
    accessPolicies: []
    enabledForDeployment: true
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: keyVault
  name: 'sqlAdminPassword'
  properties: {
      value: sqlAdminPassword
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlServerName
  location: resourceGroup().location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

// Create a firewall rule that allows Azure services to access the SQL server.
// This rule sets both startIpAddress and endIpAddress to '0.0.0.0'.
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Database using the Standard tier; we cannot quite fit into 2GB.
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  name: 'sqldb'
  location: resourceGroup().location
  properties: {
    // The collation and maxSizeBytes are set to common defaults.
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648  // 2 GB max size (adjust if necessary)
  }
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
}

// Container Registry (ACR)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Log Analytics Workspace
// This workspace is used by the managed environment to capture logs (including container output)
// for debugging purposes.
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: 'logAnalytics${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {}
}

// Managed Environment for Container Apps / Jobs.
// Here we’re enabling Log Analytics integration via appLogsConfiguration.
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvName
  location: resourceGroup().location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        // listKeys is used here to retrieve the shared key.
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Create a User Assigned Managed Identity (UAMI)
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'exporterUAMI'
  location: resourceGroup().location
}

// Role Assignment: Grant the container app job's identity the AcrPull role on the ACR.
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Use a deterministic GUID based on the UAMI's id and a unique string; role assignment names must be GUIDs
  name: guid(uami.id, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Grant the container's managed identity access to read all secrets from the Key Vault.
resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-10-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        // Uses the tenant ID from the subscription
        tenantId: subscription().tenantId
        // The principalId from the container app job’s system-assigned identity.
        objectId: uami.properties.principalId
        permissions: {
          // Grant permission to list and get (i.e. read) all secrets.
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Azure Container Apps Job
// This job resource defines the container that executes to completion.
// It is configured with a cron-based trigger (runs once per day) but can also be manually invoked.
resource containerAppJob 'Microsoft.App/jobs@2024-03-01' = {
  name: containerAppJobName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    configuration: {
      registries: [
        {
          server: registryUrl
          identity: uami.id
        }
      ]
      replicaTimeout: 28800
      triggerType: 'Schedule'
      scheduleTriggerConfig: {
        cronExpression: scheduleCron
        parallelism: 1
        replicaCompletionCount: 1
      }
    }
    environmentId: containerAppEnv.id
    template: {
      containers: [
        {
          name: containerAppJobName
          image: containerImage
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'UAMI_CLIENT_ID'
              value: uami.properties.clientId
            }
            {
              name: 'SERVER'
              value: '${sqlServerName}${environment().suffixes.sqlServerHostname}'
            }
            {
              name: 'DB'
              value: 'sqldb'
            }
            {
              name: 'ADMINUSER'
              value: sqlAdminUsername
            }
            {
              name: 'KEYVAULTNAME'
              value: keyVaultName
            }
            {
              name: 'STORAGEACCOUNTNAME'
              value: storageAccountName
            }
          ]
        }
      ]
    }
  }
}

// Storage Account.
// Hot access and geographic redundancy is overkill, but this is pennies per year so we do not care
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// Create a blob container within the Storage Account.
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${storageAccount.name}/default/${blobContainerName}'
  properties: {
    publicAccess: 'None'
  }
}

// Assign the "Storage Blob Data Reader" role to the UAMI at the blob container level.
// Role ID for Storage Blob Data Reader: 2a2b9908-6ea1-4ae2-8e65-a410df84e7d1.
resource blobDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  // A deterministic GUID is generated based on the container, identity, and role definition.
  name: guid(uami.id, blobContainer.id, '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
  scope: blobContainer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
