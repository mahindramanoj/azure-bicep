//This module creates a vnet with 'n' number of subnets in it.

@description('Location of the resource(s) deployed')
param resourceLocation string

@description('Details to create the vnet')
param virtualNetworkValues object /*= {
  name: '<Name of the vnet>'
  addressPrefix: '<Address Prefix of the vnet>'
  subnets: { //below property can be repeated based on the number of subnets needed
    <NameoftheSubnet>: {
      addressSpace: ''
      privateEndpointPolicies: 'Disabled'
      privateLinkServicePolicies: 'Enabled'
      delegations: {
        name: ''
        serviceName: 'Microsoft.Web/ServerFarms'
      }
      serviceEndpoints: false
    }
  }
}
*/

// Converts the subnets property into an array of key value pairs (dictionary object)
var subnetValues = items(virtualNetworkValues.subnets)

//create vnet with subnets
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkValues.name
  location: resourceLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkValues.addressPrefix
      ]
    }
    dhcpOptions: {}
    virtualNetworkPeerings: []
    subnets: [for subnet in subnetValues: {
      name: subnet.key
      properties: {
        addressPrefix: subnet.value.addressSpace
        privateEndpointNetworkPolicies: subnet.value.privateEndpointPolicies
        privateLinkServiceNetworkPolicies: subnet.value.privateLinkServicePolicies
        delegations: (!empty(subnet.value.delegations)) ? [
          {
            name: subnet.value.delegations.name
            properties: {
              serviceName: subnet.value.delegations.servicename
            }
          }
        ] : json('null')
        serviceEndpoints: (subnet.value.serviceEndpoints) ? [
          {
            service: 'Microsoft.Storage'
          }
          {
            service: 'Microsoft.Sql'
          }
        ] : json('null')
        serviceEndpointPolicies: []
        routeTable: json('null')
        networkSecurityGroup: json('null')
      }
    }]
  }
}

@description('Resource ID of the virtual Network that was deployed')
output vnetID string = virtualNetwork.id
@description('Address Space of the virtual network that was deployed')
output vnetAddress array = virtualNetwork.properties.addressSpace.addressPrefixes
@description('Resource Ids of the subnets that were deployed')
output deployedSubnets array = [for (subnet, i) in subnetValues : {
  ResourceId: virtualNetwork.properties.subnets[i].id
}]
