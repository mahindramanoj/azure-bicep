//Bicep module to deploy an App Service Plan in Azure

@description('Azure region where the resource will be deployed')
param resoureLocation string

@description('App Service Plan block')
param appServicePlanBlock object /*= {
  name: //string
  sku: {
    name: ''
    tier: ''
  }
  kind: //string. Allowed values are windows or linux
  maximumElasticWorkerCount: //int
}
*/
// create App service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanBlock.name
  location: resoureLocation
  kind: (appServicePlanBlock.kind == 'linux') ? 'linux': string('null')
  sku: {
    name: appServicePlanBlock.sku.name
    tier: appServicePlanBlock.sku.tier
  }
  properties: {
    maximumElasticWorkerCount: appServicePlanBlock.maximumElasticWorkerCount
    reserved: (appServicePlanBlock.kind == 'linux') ? true : json('null')
  }
}

//outputs
@description('Resource Id of the app service plan')
output aspId string = appServicePlan.id
