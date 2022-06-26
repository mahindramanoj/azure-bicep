
param resourceLocation string = resourceGroup().location

param vmAvailabilitySetName string

param vmValues object = {
  vmNamePrefix: 'my-az'
  vmVnetName: 'my-Vnet'
  vmVnetRG: 'myRG'
  vmPrimaryVnicSubnet: 'subnet1'
  vmSecondaryVnicSubnet: ''
  enableNicAcceleratedNetworking: false
  vmCount: 1
  osDiskType: 'Standard_LRS'     
  osDiskSizeGB: 128    
  dataDiskType: ''                  
  dataDiskSizeGB: ''              
  dataDiskCount: 0                 
  applyAzureHybridBenefit: false    
  bootDiagnostics: {
    enabled: true             
    storageAccountName: 'mahissbootdiagst'
    newStorageAccount: true
    storageAccountRG: ''     
  }
  customScriptExtension: {}           
}

param vmSize string = 'Standard_B2ms'

param vmAdminUsername string
@secure()
param vmAdminPasword string

// Gather resource id of the exsiting storage account depending on the user's input
resource existingBootDiagSa 'Microsoft.Storage/storageAccounts@2021-08-01' existing = if (!(vmValues.bootDiagnostics.newStorageAccount) && (vmValues.bootDiagnostics.enabled)) {
  name: vmValues.bootDiagnostics.storageAccountName
  scope: empty(vmValues.bootDiagnostics.storageAccountRG) ? resourceGroup() : resourceGroup(vmValues.bootDiagnostics.storageAccountRG)
}

// create storage account to configure boot diagnostics based on the user's input
module newBootDiagsa 'modules/Storage/storageaccount.bicep'= if (vmValues.bootDiagnostics.enabled && vmValues.bootDiagnostics.newStorageAccount) {
  name: 'vmBootDiagstorageAccount'
  scope: empty(vmValues.bootDiagnostics.storageAccountRG) ? resourceGroup() : resourceGroup(vmValues.bootDiagnostics.storageAccountRG)
  params: {
    storageAccountNamePrefix: vmValues.bootDiagnostics.storageAccountName
    resourceLocation: resourceLocation
    storageAccountKind: 'StorageV2'
    storageAccountSku: 'Standard_LRS'
  }
}

module avSet 'modules/Compute/availabilitySet.bicep' = if(!empty(vmAvailabilitySetName)) {
  name: 'availabilitySet'
  params: {
    availabilitySetName: vmAvailabilitySetName
    resourceLocation: resourceLocation
  }
}

module pvNic 'modules/Network/networkInterface.bicep' = [for nic in range(1, vmValues.vmCount): {
  name: 'vNicPrimary${nic}'
  params: {
    resourceLocation: resourceLocation
    vnetRG: vmValues.vmVnetRG
    secondaryVnicSubnetName: vmValues.vmSecondaryVnicSubnet
    enablevNicAcceleratedNetworking: vmValues.enableNicAcceleratedNetworking
    primaryVnicSubnetName: vmValues.vmPrimaryVnicSubnet
    vNicName: '${vmValues.vmNamePrefix}-vm${nic}_nic1'
    vNicVnetName: vmValues.vmVnetName
  }
}]

module svNic 'modules/Network/networkInterface.bicep' = [for nic in range(1, vmValues.vmCount): if(!empty(vmValues.vmSecondaryVnicSubnet)) {
  name: 'vNicSecondary${nic}'
  params: {
    resourceLocation: resourceLocation
    vnetRG: vmValues.vmVnetRG
    secondaryVnicSubnetName: vmValues.vmSecondaryVnicSubnet
    enablevNicAcceleratedNetworking: vmValues.enableNicAcceleratedNetworking
    primaryVnicSubnetName: vmValues.vmPrimaryVnicSubnet
    vNicName: '${vmValues.vmNamePrefix}-vm${nic}_nic2'
    vNicVnetName: vmValues.vmVnetName
  }
}]

module wvm 'winvm.bicep' = [for vm in range(0, vmValues.vmCount) : {
  name: 'virtualMachine${vm+1}'
  params: {
    vmSize: vmSize
    bootDiagStorageAccountUri: (!(vmValues.bootDiagnostics.newStorageAccount) && (vmValues.bootDiagnostics.enabled)) ? existingBootDiagSa.properties.primaryEndpoints.blob : (vmValues.bootDiagnostics.enabled && (vmValues.bootDiagnostics.newStorageAccount)) ? newBootDiagsa.outputs.storageAccountBlobEndpoint : string('null')
    dataDiskCount: vmValues.dataDiskCount
    dataDiskSizeGB: (empty(vmValues.dataDiskSizeGB) || (vmValues.dataDiskSizeGB == 0)) ? int(1) : int(vmValues.dataDiskSizeGB)
    dataDiskType: empty(vmValues.dataDiskType) ? 'Standard_LRS' : vmValues.dataDiskType
    resourceLocation: resourceLocation
    vmAdminPassword: vmAdminPasword
    vmAdminUsername: vmAdminUsername
    vmName: '${vmValues.vmNamePrefix}-vm${vm+1}'
    vmPrimaryvNicId: pvNic[vm].outputs.vNicId
    vmSecondaryvNicId: !empty(vmValues.vmSecondaryVnicSubnet) ? svNic[vm].outputs.vNicId : string('null')
  }
}]

module customScriptExtension 'modules/Compute/customscriptextension.bicep' = [for i in range(0, vmValues.vmCount): if(!empty(vmValues.customScriptExtension)) {
  name: '${vmValues.vmNamePrefix}-vm${i+1}-extension'
  params: {
    resourceLocation: resourceLocation
    customScriptExtentionName: '${vmValues.vmNamePrefix}-vm${i+1}/${vmValues.customScriptExtension.name}'
    scriptStorageAccountName: vmValues.customScriptExtension.storageAccountName
    scriptStorageAccountRG: vmValues.customScriptExtension.storageAccountRG
    scriptPathinStorageAccount: vmValues.customScriptExtension.scriptPath
    commandToExecute: vmValues.customScriptExtension.commandToExecute
  }
}]

output vmId array = [for vm in range(0, vmValues.vmCount) : wvm[vm].outputs.resourceId ]

