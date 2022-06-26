//Bicep module to create private endpoint (for the supported resource)

@description('Azure region where the resource will be deployed')
param resourceLocation string

@description('Name prefix of the private endpoint')
param privateEndpointNamePrefix string

@description('Resource Id of the subnet where the private endpoint will be deployed')
param privateEndpointSubnetId string

@description('Resource Id of the Azure resource for which private link service will be enabled')
param privateLinkServiceId string

@description('Sub resource of the azure service for which private link gets created')
param privateLinkServiceGroupId string

@description('Name of the private dns zone group configuration for the private endpoint')
param privateDNSZoneConfigName string

@description('Resource Id of the private DNS zone to which the private endpoint will be registered')
param privateDNSZoneId string

// Create private endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${privateEndpointNamePrefix}-pe'
  location: resourceLocation
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointNamePrefix}-pe'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            privateLinkServiceGroupId
          ]
        }
      }
    ]
  }
  resource privateDNSConfig 'privateDNSZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: privateDNSZoneConfigName
          properties: {
            privateDnsZoneId: privateDNSZoneId
          }
        }
      ]
    }
  }
}

//outputs
@description('Resource Id of the private endpoint')
output resourceId string = privateEndpoint.id
