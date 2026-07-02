@description('Naming prefix applied to all resources created here')
param prefix string

@description('Region for deployment')
param location string

@description('Address space for the VNet')
param vnetAddressSpace array = [
  '10.0.0.0/16'
]

@description('List of subnets to create')
param subnets array = [
  {
    name: 'default'
    addressPrefix: '10.0.1.0/24'
  }
]

@description('Allow inbound HTTP from any')
param enableHttp bool = false

@description('Allow inbound HTTPS from any')
param enableHttps bool = false

@description('CIDR allowed to access management (SSH/RDP). Must be single IP with /32 suffix. Leave empty to disable management access entirely.')
param managementAllowedCidr string = ''

@description('Management ports to open if managementAllowedCidr is set')
param managementPorts array = [22, 3389]

@description('Tags to apply to all resources')
param tags object = {}

var managementPortsAsStrings = [for port in managementPorts: string(port)]

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${prefix}-nsg'
  location: location 
  tags: tags 
  properties: {
    securityRules: concat(
      enableHttp ? [
        {
          name: 'allow-http'
          properties: {
            priority: 100
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '80'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ] : [],
      enableHttps ? [
        {
          name: 'allow-https'
          properties: {
            priority: 110
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ] : [],
      !empty(managementAllowedCidr) ? [
        {
          name: 'allow-management'
          properties: {
            priority: 120
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRanges: managementPortsAsStrings
            sourceAddressPrefix: managementAllowedCidr
            destinationAddressPrefix: '*'
          }
        }
      ] : [],
      [
        {
          name: 'deny-all-inbound'
          properties: {
            priority: 4096
            direction: 'Inbound'
            access: 'Deny'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ]
    )
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressSpace
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: nsg.id
        }
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetIds array = [for (subnet, i) in subnets: vnet.properties.subnets[i].id]
output nsgId string = nsg.id
