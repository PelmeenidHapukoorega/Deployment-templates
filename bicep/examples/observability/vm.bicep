@description('Naming prefix for all resources')
param prefix string

@description('Region to deploy into')
param location string

@description('Subnet ID for the VM nic')
param subnetId string

@description('SSH public key for the VM admin user')
param sshPublicKey string

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${prefix}-vm-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${prefix}-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ] 
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: '${prefix}-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2as_v6'
    }
    osProfile: {
      computerName: '${prefix}-vm'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ] 
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ] 
    }
  }
}

output vmId string = vm.id
output vmPublicIp string = publicIp.properties.ipAddress
