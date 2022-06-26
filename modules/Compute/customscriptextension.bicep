//Module to provision custom script extension on the virtual machine for the post vm deployment configuration

@description('Azure region of the custom script extension')
param resourceLocation string

@description('Name of the custom script extension')
param customScriptExtentionName string

@description('Name of the storage Account where the script resides')
param scriptStorageAccountName string

@description('Name of the resource group where the storage Account resides')
param scriptStorageAccountRG string

@description('Script path within the storage account')
param scriptPathinStorageAccount string //eg: scripts/script.ps1 i.e. <containername>/<scriptname> relative to the storage account name parameter

@description('Command to be executed by the custom script extension')
param commandToExecute string

// Gather resource id for the storage account of the script
resource scriptStorageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: scriptStorageAccountName
  scope: empty(scriptStorageAccountRG) ? resourceGroup() : resourceGroup(scriptStorageAccountRG)
}

// Deploy custom script extension
resource customScriptExt 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: customScriptExtentionName
  location: resourceLocation
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      storageAccountName: scriptStorageAccountName
      storageAccountKey: listKeys(scriptStorageAccount.id, scriptStorageAccount.apiVersion).keys[0].value
      fileUris: array('scriptStorageAccount.properties.primaryEndpoints.blob/${scriptPathinStorageAccount}')
      commandToExecute: commandToExecute
    }
  }
}

//outputs from this bicep module
output resourceId string = customScriptExt.id
