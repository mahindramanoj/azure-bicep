// Bicep module to deploy API M

@description('Azure region where the resource will be deployed')
param resourceLocation string
@description('Api Management Service values')
param apimValues object = {
  name: ''
  sku: {
    name: ''
    capacity: 1 
  }
  enableManagedIdentity: true
  publisherName: ''
  publisherEmail: ''
  vnetType: 'External'
  vnetName: ''
  vnetRG: ''
  subnetName: ''
  appInsightsValues: {
    name: ''                      
    kind: ''                      
    applicationType: ''
    newWorkspace: true
    workspaceRG: ''
    workspace: {
      name: ''  
      sku: ''
    }
  }
}

// create app insight for the APIM
module appInsightsApim '../Monitor/appinsights.bicep' = {
  name: 'apimAppInsight'
  params: {
    appInsightsValues: apimValues.appInsightsValues
    resourceLocation: resourceLocation
  }
}

// resource Id of the vnet that API M will use
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: apimValues.vnetName
  scope: (!empty(apimValues.vnetRG)) ? resourceGroup(apimValues.vnetRG) : resourceGroup()
}

// resource ID of the subnet api M will be integrated with
resource snet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: apimValues.subnetName
  parent: vnet
}

// deploy API Management service
resource apim 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apimValues.name
  location: resourceLocation
  identity: apimValues.enableManagedIdentity ? {
    type: 'SystemAssigned'
  }: json('null')
  sku: {
    capacity: apimValues.sku.capacity
    name: apimValues.sku.name
  }
  properties: {
    publisherEmail: apimValues.publisherEmail
    publisherName: apimValues.publisherName
    virtualNetworkType: apimValues.vnetType
    virtualNetworkConfiguration: {
      subnetResourceId: snet.id
    }
  }
  resource apimLogger 'loggers@2021-08-01' = {
    name: '${apimValues.name}-appi'
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appInsightsApim.outputs.appInsightsId
      credentials: {
        instrumentationKey:appInsightsApim.outputs.appInsightsKey
      }
    }
  }
  resource apimDiagnostics 'diagnostics@2021-08-01' = {
    name: 'applicationInsights'
    properties: {
      loggerId: apimLogger.id
      alwaysLog: 'allErrors'
      sampling: {
        percentage: 100
        samplingType: 'fixed'
      }
    }
  }
}

//outputs
@description('Resource Id of the API Management service that was created')
output apimServiceId string = apim.id
@description('Resource Id of the application insight that created for the APIM service')
output apimAppInsightId string = appInsightsApim.outputs.appInsightsId
@description('Resource Id of the log analytics workspace that was created as a part of this deployment')
output apimLogAnalyticsId string = apimValues.appInsightsValues.newWorkspace ? appInsightsApim.outputs.logAnalyticsWorkspaceId : string('null')
