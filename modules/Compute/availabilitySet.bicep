@description('Details of the availability set described')
param availabilitySetName string

@description('Location where the availabily set will be deployed')
param resourceLocation string

// Create an availability set
resource avset 'Microsoft.Compute/availabilitySets@2021-11-01' = {
  name: availabilitySetName
  location: resourceLocation
  sku: {
    name: 'aligned'
  }
  properties: {
    platformFaultDomainCount: 5
    platformUpdateDomainCount: 3
  }
}
//outputs 
output Id string = avset.id
