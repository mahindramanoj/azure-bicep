//This module creates 'n' subnets in a virtual network that is already deployed

@description('Name of the virtual network in which the subnet(s) will be created')
param vnetName string

@description('Subnet(s) that the vnet will have')
param subnetValues object

// Converts the subnetBlock dictonary object into an array of key value pairs
var subnetBlock = items(subnetValues)

// Calling the virtual network resource that was already deployed
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

// Create subnets 
@batchSize(1)
resource subnets 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' =  [for subnet in subnetBlock : if(subnetBlock != json('null')) {
  name: subnet.key
  parent: vnet
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

@description('Resource Ids of the subnets that were deployed')
output deployedSubnets array = [for (subnet, i) in subnetBlock : {
  ResourceId: subnets[i].id
}]
