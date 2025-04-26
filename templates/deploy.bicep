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

// SQL Database using the Basic tier
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  //name: '${sqlServer.name}/sqldb'
  name: 'sqldb'
  location: resourceGroup().location
  properties: {
    // The collation and maxSizeBytes are set to common defaults.
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648  // 2 GB max size (adjust if necessary)
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
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