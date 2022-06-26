
param resourceLocation string

param vmName string

param vmSize string

param vmAdminUsername string

@secure()
param vmAdminPassword string

param vmPrimaryvNicId string

param vmSecondaryvNicId string

param bootDiagStorageAccountUri string

param dataDiskCount int

param dataDiskType string

param dataDiskSizeGB int

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: resourceLocation
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-Gensecond'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [ for d in range(0, dataDiskCount) : {
        name: '${vmName}_DataDisk_${d}'
        lun: d
        createOption: 'Empty'
        caching: 'None'
        diskSizeGB: dataDiskSizeGB
        managedDisk: {
          storageAccountType: dataDiskType
        }
      }]
    }
    networkProfile: {
      networkInterfaces: !empty(vmSecondaryvNicId) ? [
        {
          id: vmPrimaryvNicId
          properties: {
            primary: true
          }
        }
        {
          id: vmSecondaryvNicId
          properties: {
            primary: false
          }
        }
      ] : [
        {
          id: vmPrimaryvNicId
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri:  bootDiagStorageAccountUri
      }
    }
  }
}

output resourceId string = vm.id
