//Bicep module to create private DNS Zone

@description('Name of the privateDNSZone')
param privateDNSZoneName string

@description('Name of the vnet that will be linked with dns zone')
param privateDNSZoneVnetName string

@description('Resource Id of the vnet that will be linked with dns zone')
param PrivateDNSZoneVnetId string


// create privateDNSZone and link it with a vnet
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  properties: {}
  resource dnsVnetLink 'virtualNetworkLinks' = {
    name: '${privateDNSZoneVnetName}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: PrivateDNSZoneVnetId
      }
    }
  }
}

//outputs
@description('Resource ID of the private dns zone')
output resourceId string = privateDNSZone.id
