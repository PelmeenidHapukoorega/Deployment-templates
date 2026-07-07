@description('Naming prefix for all resources')
param prefix string

@description('Region to deploy into')
param location string

@description('Creates KV alongside MI Only enable when non-Azure secrets need storing: prefer the MI for Azure-to-Azure auth.')
param enableKeyVault bool = false

@description('SKU for the KV if created')
param keyVaultSku string = 'standard'

@description('Tags to apply to all resources')
param tags object = {}


resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}-identity'
  location: location
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (enableKeyVault) {
  name: '${prefix}-kv'
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableKeyVault) {
  name: guid(keyVault.id, identity.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


output identityId string = identity.id
output identityPrincipalId string = identity.properties.principalId
output identityClientId string = identity.properties.clientId
output keyVaultId string = enableKeyVault ? keyVault.id : ''
output keyVaultUri string = enableKeyVault ? keyVault.properties.vaultUri : ''
