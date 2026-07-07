targetScope = 'subscription'

@description('Naming prefix to all resources')
param prefix string = 'secmodtest'

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
    enableKeyVault: true
    tags: {
      Environment: 'Test'
      Project: 'security-module-example'
    }
  }
}

output identityId string = security.outputs.identityId
output identityPrincipalId string = security.outputs.identityPrincipalId
output identityClientId string = security.outputs.identityClientId
output keyVaultId string = security.outputs.keyVaultId
output keyVaultUri string = security.outputs.keyVaultUri
