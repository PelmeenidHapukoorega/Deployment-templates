targetScope = 'subscription'

@description('Naming prefix for all resources')
param prefix string = 'netmodtest'

@description('Region where resources would be deployed')
param location string = 'westeurope'

@description('Current public IP used to allow management access. Leave empty to disable management access entirely.')
param myIp string = ''

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-rg'
  location: location
}

module networking '../../modules/networking/main.bicep' = {
  name: 'networkingDeployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
    subnets: [
      {
        name: 'web'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'data'
        addressPrefix: '10.0.2.0/24'
      }
    ]
    enableHttp: true
    enableHttps: true
    managementAllowedCidr: !empty(myIp) ? '${myIp}/32' : ''
    tags: {
      Environment: 'Test'
      Project: 'networking-module-example'
    }
  }
}

output vnetId string = networking.outputs.vnetId
output vnetName string = networking.outputs.vnetName
output subnetIds array = networking.outputs.subnetIds
output nsgId string = networking.outputs.nsgId
