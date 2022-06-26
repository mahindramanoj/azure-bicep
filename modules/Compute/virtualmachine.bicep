// This bicep module creates n number of windows 2019 gen 2 vms, lets you enable managed system identity 
// It calls several other bicep modules behind the scenes to deploy the required resources before creating the vm(s)

@description('Azure region where the resources will be deployed')
param resourceLocation string
@description('Name of the availability Set')
param availabilitySetName string = '' //keep it empty if you don't want an availabilitySet
@description('Instance size the vm(s) will have')
param vmSize string
@description('Object containning the values related to vm(s)')
param vmValues object = {
/* vmNamePrefix:                   //string. virtual machine name prefix. Should not be more than 12 chars
    vmVnetRg:                      //string. Resource group of the vnet used by the vm or vms
    vmVnetName:                    //string. Vnet where the vm(s) reside
    primaryVicSubnetName:          //string. Subnet where the primary nic of the vm(s) will be deployed
    secondaryVnicSubnetName:       //string or empty String. Subnet where the sec nic of the vm(s) will be deployed (OPTIONAL)
    enableAcceleratedNetworking:   //bool. Enable accelerated networking on the primary vNic depending on the size of the vm(s)
    enableManagedIdentity:         //bool. Set it to true to enable Managed System Identity
    vmCount:                       //int. Number of vms to be deployed
    osDiskType:                    //string. Supports only one type from: Standard_LRS, StandardSSD_LRS, Premium_LRS
    osDiskSizeGB:                  //int. OS Disk size in GB
    dataDiskType:                  //string. Supports only one type from: Standard_LRS, StandardSSD_LRS, Premium_LRS, UltraSSD_LRS
    dataDiskSizeGB:                //int. Data Disk size in GB. Should be empty ('') when there is no need for data disk(s)
    dataDiskCount:                 //int. No. of Data Disks to be attached to the vm(s)
    applyAzureHybridBenefit:       //bool.
    bootDiagnostics: {
      enabled:                     //bool. Set it to false if you do not want to configure boot diagnostics for the vm(s)
      storageAccountName:          //string. Keep it empty if you want to have a managed storage account with enabled key set to true
      newStorageAccount:           //bool. Setting it to true will deploy the storage account and associate it to the vm(s)
      storageAccountRG:            //string. Keep it empty if you are creating a new storage account for vm boot diagnostics
    }
    customScriptExtension: {       // Keep it {} if the vm or vms do not need to execute a custom script using the extension
      name:                        //string
      storageAccountName:          //string
      storageAccountRG:            //string. Keep it empty if the storage account where the script is uploaded in the same RG where the bicep config file gets deployed
      scriptPath:                  //string. Path to the script in the mentioned storage account
      commandToExecute:            //string. Command to be executed by the custom script extension
      parameters: {}               //object. OPTIONAL and mandatory if the custom script is parameterized
    }
    */
}
@description('Local Admin Username for the vm(s)')
param vmAdminUsername string
@description('Local Admin Password for the vm(s)')
@secure()
param vmAdminPassword string

// Gather resource id of the exsiting storage account depending on the user's input
resource existingBootDiagSa 'Microsoft.Storage/storageAccounts@2021-08-01' existing = if (!(vmValues.bootDiagnostics.newStorageAccount) && (vmValues.bootDiagnostics.enabled)) {
  name: vmValues.bootDiagnostics.storageAccountName
  scope: empty(vmValues.bootDiagnostics.storageAccountRG) ? resourceGroup() : resourceGroup(vmValues.bootDiagnostics.storageAccountRG)
}

// create storage account to configure boot diagnostics based on the user's input
module newBootDiagsa '../Storage/storageaccount.bicep' = if (vmValues.bootDiagnostics.enabled && vmValues.bootDiagnostics.newStorageAccount) {
  name: 'vmBootDiagstorageAccount'
  scope: empty(vmValues.bootDiagnostics.storageAccountRG) ? resourceGroup() : resourceGroup(vmValues.bootDiagnostics.storageAccountRG)
  params: {
    storageAccountNamePrefix: vmValues.bootDiagnostics.storageAccountName
    resourceLocation: resourceLocation
    storageAccountKind: 'StorageV2'
    storageAccountSku: 'Standard_LRS'
  }
}

// Conditionally create an availability set
module availset 'availabilitySet.bicep' = if(!empty(availabilitySetName)) {
  name: 'avset'
  params: {
    availabilitySetName: availabilitySetName
    resourceLocation: resourceLocation
  }
}

// Create primary vNics for the vm(s)
module pNicModule '../Network/networkInterface.bicep' = [for vnic in range(1, vmValues.vmCount): {
  name: 'vNicPrimary${vnic}'
  params: {
    vNicName: '${vmValues.vmNamePrefix}-vm${vnic}_nic1'
    vNicVnetName: vmValues.vmVnetName
    vnetRG: vmValues.vmVnetRG
    primaryVnicSubnetName: vmValues.primaryVnicSubnetName
    secondaryVnicSubnetName: ''
    resourceLocation: resourceLocation
    enablevNicAcceleratedNetworking: vmValues.enablevNicAcceleratedNetworking
  }
}]

module sNicModule '../Network/networkInterface.bicep' = [for vnic in range(1, vmValues.vmCount) : if(!empty(vmValues.secondaryVnicSubnetName)) {
  name: 'vNicSecondary${vnic}'
  params: {
    vNicName: '${vmValues.vmNamePrefix}-vm${vnic}_nic2'
    vNicVnetName: vmValues.vmVnetName
    vnetRG: vmValues.vmVnetRG
    primaryVnicSubnetName: ''
    secondaryVnicSubnetName: vmValues.secondaryVnicSubnetName
    resourceLocation: resourceLocation
    enablevNicAcceleratedNetworking: false
  }
}]

//Create Windows VM(s)
module wvm 'windows-vm-resource.bicep' = [for vm in range(0, vmValues.vmCount) : {
  name: 'virtualMachine${vm+1}'
  params: {
    vmSize: vmSize
    bootDiagStorageAccountUri: (!(vmValues.bootDiagnostics.newStorageAccount) && (vmValues.bootDiagnostics.enabled)) ? existingBootDiagSa.properties.primaryEndpoints.blob : (vmValues.bootDiagnostics.enabled && (vmValues.bootDiagnostics.newStorageAccount)) ? newBootDiagsa.outputs.storageAccountBlobEndpoint : string('null')
    dataDiskCount: vmValues.dataDiskCount
    dataDiskSizeGB: (empty(vmValues.dataDiskSizeGB) || (vmValues.dataDiskSizeGB == 0)) ? int(1) : int(vmValues.dataDiskSizeGB)
    dataDiskType: empty(vmValues.dataDiskType) ? 'Standard_LRS' : vmValues.dataDiskType
    resourceLocation: resourceLocation
    vmAdminPassword: vmAdminPassword
    vmAdminUsername: vmAdminUsername
    vmName: '${vmValues.vmNamePrefix}-vm${vm+1}'
    vmPrimaryvNicId: pNicModule[vm].outputs.vNicId
    vmSecondaryvNicId: !empty(vmValues.vmSecondaryVnicSubnet) ? sNicModule[vm].outputs.vNicId : string('null')
  }
}]


// Calls customScriptExtension module to provision extension on the deloyed vm(s)
module customScriptExtension 'customscriptextension.bicep' = [for i in range(0, vmValues.vmCount): if(!empty(vmValues.customScriptExtension)) {
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

//outputs from this bicep module
output vmsId array = [for o in range (0, vmValues.vmCount): wvm[o].outputs.resourceId]

output vmsPrimaryNicIp array = [for o in range(0, vmValues.vmCount): pNicModule[o].outputs.vNicIPaddress]

output vmsSecondaryNicIp array = [for o in range (0, vmValues.vmCount): (!empty(vmValues.secondaryVnicSubnetname)) ? sNicModule[o].outputs.vNicIPaddress : json('null')]

