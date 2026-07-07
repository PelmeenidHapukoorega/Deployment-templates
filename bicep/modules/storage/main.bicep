@description('Naming prefix for all resources')
param prefix string

@description('Region to deploy into')
param location string

@description('Replication type for ST account')
param accountReplicationType string = 'LRS'

@description('Access tier for ST account')
param accessTier string = 'Hot'

@description('List of blob container names to create')
param containers array = []

@description('Whether public network access is allowed, disabled by default')
param publicNetworkAccessEnabled bool = false

@description('List of MI principal Ids to grant Storage Blob Data contributor access')
param identityPrincipalIdsWithAccess array = []

@description('Tags for resources')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: take('${prefix}sa${uniqueString(resourceGroup().id)}', 24)
  location: location
  sku: {
    name: 'Standard_${accountReplicationType}'
  }
  kind: 'StorageV2'
  tags: tags
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: publicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource containersResource 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for containerName in containers : {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}]

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in identityPrincipalIdsWithAccess: {
  name: guid(storageAccount.id, principalId, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output containerIds array = [for (containerName, i) in containers: containersResource[i].id]
