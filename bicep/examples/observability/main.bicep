targetScope = 'subscription'

@description('Naming prefix for all resources')
param prefix string = 'obsmodtest'

@description('Region to deploy into')
param location string = 'westeurope'

@description('Current public IP, used for management access. Leave empty disable MA')
param myIp string = ''

@description('Email address for alert notifs')
param alertEmail string = ''

@description('SSH public key for test VM admin user')
param sshPublicKey string

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
            {name: 'default', addressPrefix: '10.0.1.0/24'}
        ] 
        managementAllowedCidr: !empty(myIp) ? '${myIp}/32' : ''
    }
}

module vmResources 'vm.bicep' = {
    name: 'vmDeployment'
    scope:rg
    params: {
        prefix: prefix
        location: location
        subnetId: networking.outputs.subnetIds[0]
        sshPublicKey: sshPublicKey
    }
}

module observability '../../modules/observability/main.bicep' = {
    name: 'observabilityDeployment'
    scope: rg
    params: {
        prefix: prefix
        location: location
        alertEmail: alertEmail
        alertTargets: [vmResources.outputs.vmId]
        tags: {
            Environment: 'Test'
            Project: 'observability-module-example'
        }
    }
}

output vmId string = vmResources.outputs.vmId
output vmPublicIp string = vmResources.outputs.vmPublicIp
output workspaceId string = observability.outputs.workspaceId
output workspaceName string = observability.outputs.workspaceName
output actionGroupId string = observability.outputs.actionGroupId
