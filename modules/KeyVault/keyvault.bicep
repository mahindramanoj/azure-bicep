//Bicep module to deploy key vault

@description('Name of the key vault')
param keyVaultName string

@description('Azure region where the resource will be created')
param resourceLocation string

@description('Tenant Id that will be used by the key vault')
param tenantId string

// create key vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    accessPolicies: []
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
  }
}

@description('Resource id of the key vault that got created')
output resourceId string = keyVault.id
