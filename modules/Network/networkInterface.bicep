//This module crates a vNIC that can be associated to a vm in Azure

@description('Name prefix of the vNIC')
param vNicName string

@description('Virtual Network that will be used by the vNIC')
param vNicVnetName string

@description('Resource Group where the vnet was deployed')
param vnetRG string

@description('Subnet where the primary vNic will be deployed')
param primaryVnicSubnetName string

@description('Subnet where the secondary vNic will be deployed')
param secondaryVnicSubnetName string

@description('Location of the resource being deployed')
param resourceLocation string

@description('Enable accelerated networking on the vNic')
param enablevNicAcceleratedNetworking bool

// Resource Id of the subnet that the primary vNIC will use

resource vNicVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vNicVnetName
  scope: empty(vnetRG) ? resourceGroup() : resourceGroup(vnetRG)
}

// resource id of the subnet that the secondary vNIC will use only if it is not same as the one the primary Nic uses
resource pVNicSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = if(empty(secondaryVnicSubnetName)) {
  name: primaryVnicSubnetName  
  parent: vNicVnet
}

resource sVnicSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = if(!empty(secondaryVnicSubnetName)) {
  name: secondaryVnicSubnetName
  parent: vNicVnet
}

// Crate network interface
resource vNic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: vNicName
  location: resourceLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: empty(secondaryVnicSubnetName) ? pVNicSubnet.id : sVnicSubnet.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: enablevNicAcceleratedNetworking
  }
}

//outputs from this module
output vNicId string = vNic.id
output vNicIPaddress string = vNic.properties.ipConfigurations[0].properties.privateIPAddress
