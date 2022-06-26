// Bicep module to deploy storage account

@description('Name of the storage account that will be deployed')
param storageAccountNamePrefix string
@description('Azure region where the storage account will be deployed')
param resourceLocation string
@description('Storage account SKU')
param storageAccountSku string
@description('Type of the storage account that will be deployed')
param storageAccountKind string

/* var st = {
  storageAccountNamePrefix: ''
  sku: ''
  kind: ''
  isHnsEnabled: ''
  isSftpEnabled: ''
} */

// create storage account in Azure
resource sa 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountNamePrefix
  location: resourceLocation
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    allowCrossTenantReplication: true
    defaultToOAuthAuthentication: false
    isHnsEnabled: false
    isSftpEnabled: false
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        table: {
          enabled: true
        }
        queue: {
          enabled: true
        }
      }
      requireInfrastructureEncryption: false
    }
    networkAcls: json('null')
    publicNetworkAccess: 'Enabled'
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
    }
  }
}
// create default blob Service for the storage account
resource defaultBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  name: 'default'
  parent: sa
  properties: {
    automaticSnapshotPolicyEnabled: false
    changeFeed: {
      enabled: true
      retentionInDays: 7
    }
    containerDeleteRetentionPolicy: {
      days: 7
      enabled: true
    }
    restorePolicy: {
      enabled: false
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}
// create default file service for the storage account
resource defaultFile 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
  name: 'default'
  parent: sa
  dependsOn: [
    defaultBlob
  ]
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
//outputs from this bicep module
output storageAccountId string = sa.id
output storageAccountBlobEndpoint string = sa.properties.primaryEndpoints.blob
output storageAccountFileEndpoint string = sa.properties.primaryEndpoints.file
output storageAccountQueueEndpoint string = sa.properties.primaryEndpoints.queue
output storageAccountTableEndpoint string = sa.properties.primaryEndpoints.table
