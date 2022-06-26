
param resourceLocation string = resourceGroup().location

param keyVaultName string

param tenantId string

param appServicePlanValues object

param webAppValues object 

param apimValues object

resource webAppVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: webAppValues.vnetIntegration.vnetName
  scope: !empty(webAppValues.vnetIntegration.vnetRG) ? resourceGroup(webAppValues.vnetIntegration.vnetRG) : resourceGroup()
}

resource webAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: webAppValues.vnetIntegration.subnet
  parent: webAppVnet
}

resource webAppEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: webAppValues.privateEndpoint.subnet
}

module kvault 'modules/KeyVault/keyvault.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: keyVaultName
    resourceLocation: resourceLocation
    tenantId: tenantId
  }
}

module app 'modules/Apps/websites.bicep' = {
  name: 'webApp'
  params: {
    appServicePlanvalues: appServicePlanValues
    appSettings: webAppValues.appSettings
    enableManagedIdenity: webAppValues.enableManagedIdentity
    resourceLocation: resourceLocation
    vnetSubnetId: webAppSubnet.id
    webSiteKind: webAppValues.kind
    webSiteName: webAppValues.name
  }
}

module dnsZone 'modules/Network/privateDNS.bicep' = {
  name: 'webAppPrivateDNSZone'
  params: {
    privateDNSZoneName: webAppValues.privateDNSZone.name
    PrivateDNSZoneVnetId: webAppVnet.id
    privateDNSZoneVnetName: webAppValues.vnetIntegration.vnetName
  }
}

module appPrivateEndpoint 'modules/Network/privateendpoint.bicep' = {
  name: 'webAppPrivateEndpoint'
  params: {
    privateDNSZoneConfigName: replace(webAppValues.privateDnsZone.name, '.', '-')
    privateDNSZoneId: dnsZone.outputs.resourceId
    privateEndpointNamePrefix: webAppValues.name
    privateEndpointSubnetId: webAppEndpointSubnet.id
    privateLinkServiceGroupId: webAppValues.privateEndpoint.subResource
    privateLinkServiceId: app.outputs.websiteId
    resourceLocation: resourceLocation
  }
}

module apiMService 'modules/Apps/apimservice.bicep' = {
  name: 'apiManagementService'
  dependsOn: [
    app
  ]
  params: {
    resourceLocation: resourceLocation
    apimValues: apimValues
  }
}

//outputs
output webAppId string = app.outputs.websiteId
output appServicePlanId string = app.outputs.appServicePlanId
output apiManagementServiceId string = apiMService.outputs.apimServiceId
//output webAppAppInsightId string = app.outputs
output webAppPrivateDNSZoneId string = dnsZone.outputs.resourceId
output webAppPrivateEndpointId string = appPrivateEndpoint.outputs.resourceId
output keyVaultId string = kvault.outputs.resourceId
