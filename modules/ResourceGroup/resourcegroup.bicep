targetScope= 'subscription'

param resourceGroupBlock object = {
  name: 'myRG'
  location: 'canadacentral'
  tags: {}
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupBlock.name
  location: resourceGroupBlock.location
  tags: !empty(resourceGroupBlock.tags) ? resourceGroupBlock.tags : json('null')
  properties: {}
}

output resourceId string = resourceGroup.id
