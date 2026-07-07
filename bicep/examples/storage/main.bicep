targetScope = 'subscription'

@description('Naming prefix for all resources')
param prefix string = 'stomodtest'

@description('Region to deploy into')
param location string = 'westeurope'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-rg'
  location: location
}

module security '../../modules/security/main.bicep' = {
  name: 'securityDeployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
    enableKeyVault: false
    tags: {
      Environment: 'Test'
      Project: 'storage-module-example'
    }
  }
}

module storage '../../modules/storage/main.bicep' = {
  name: 'storageDeployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
    containers: ['uploads', 'logs']
    identityPrincipalIdsWithAccess: [
      security.outputs.identityPrincipalId
    ] 
    tags: {
      Environment: 'Test'
      Project: 'storage-module-example'
    }
  }
}


output stoageAccountId string = storage.outputs.storageAccountId
output storageAccountName string = storage.outputs.storageAccountName
output primaryBlobEndpoint string = storage.outputs.primaryBlobEndpoint
output containerIds array = storage.outputs.containerIds
output identityPrincipalId string = security.outputs.identityPrincipalId
