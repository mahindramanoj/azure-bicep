// Bicep config file to set up things in Azure
targetScope = 'subscription'

param resourceLocation string = deployment().location

param resourceGroupBlock object

param virtualNetworkName string 

param virtualNetworkAddressPrefix string

param subnetBlock object

param vmAvailabilitySetName string

param vmSize string = 'Standard_B2ms'

param vmValues object

param vmAdminUsername string = 'vmlocadmin'

@secure()
param vmAdminPassword string


module rg 'modules/ResourceGroup/resourcegroup.bicep' = {
  name: 'resourceGroup'
  params: {
    resourceGroupBlock: resourceGroupBlock
  }
}

module vnetSnet 'modules/Network/vnetwithsubnets.bicep' = {
  scope: resourceGroup(resourceGroupBlock.name)
  name: 'virtualNetwork'
  dependsOn: [
    rg
  ]
  params: {
    resourceLocation: resourceLocation
    virtualNetworkName: virtualNetworkName
    vnetAddressSpace:  virtualNetworkAddressPrefix
    subnetBlock: subnetBlock
  }
}

module vm 'modules/Compute/virtualmachine.bicep' = {
  name: 'windows'
  scope: resourceGroup(resourceGroupBlock.name)
  dependsOn: [
    rg
    vnetSnet
  ]
  params: {
    vmAdminPassword: vmAdminPassword  
    vmAdminUsername: vmAdminUsername
    vmSize: vmSize
    vmValues: vmValues
    resourceLocation: resourceLocation
    availabilitySetName: vmAvailabilitySetName
  }
}

//output(s) of this bicep config file
output vmsId array = [for i in range(0, vmValues.vmCount): {
  vmResourceId: vm.outputs.vmsId[i]
}]

output vmsPrimaryIPAddress array = [for i in range(0, vmValues.vmCount): vm.outputs.vmsPrimaryNicIp[i]]

