//bicep module to deloy resource of type 'Microsoft.Web/sites'

@description('Azure region where the resource will be deployed')
param resourceLocation string

@description('Name of the function app or web app')
param webSiteName string

@description('App service plan hosting platform')
param webSiteKind string

@description('Boolean to enable system assigned managed identity on the app')
param enableManagedIdenity bool

@description('SSL binding for the app if any')
param hostNameSslStates array = []

@description('App settings for the app')
param appSettings array

@description('Resource Id of the subnet that will be used by the app for vnet integration')
param vnetSubnetId string

param appServicePlanvalues object = {
  name: 'mahiss-asp' //string
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'windows' //Allowed values are windows or linux
  maximumElasticWorkerCount: 3
}

/*param webSiteBlock object = {
  name: //string
  kind: '' //string. Allowed values are 'functionapp' and 'app'
  enableManagedIdentity: '' //bool
  vnetIntegration: { //OPTIONAL (can be dempty if vnet integration is not needed)
    vnetName: //string
    vnetRg: //string
    subnetName: //string
  }
  properties: {
    hostNameSslStates: []
    appSettings: [] //shouldn't be empty. Refer documentation for the required app settings on the app
  }
}*/  

//Create ASP to host the app
module asp 'appserviceplan.bicep' = {
  name: 'appServicePlan'
  params: {
    appServicePlanBlock: appServicePlanvalues
    resoureLocation: resourceLocation
  }
}

// create web app or function app
resource webSite 'Microsoft.Web/sites@2021-03-01' = {
  name: webSiteName
  location: resourceLocation
  kind: webSiteKind
  identity: (enableManagedIdenity) ? {
    type: 'SystemAssigned'
  }: json('null')
  properties: {
    enabled: true
    clientAffinityEnabled: true
    clientCertEnabled: false
    hostNamesDisabled: false
    httpsOnly: true
    hostNameSslStates: !empty(hostNameSslStates) ? hostNameSslStates : json('null')
    serverFarmId: asp.outputs.aspId
    siteConfig: {
      appSettings: !empty(appSettings) ? appSettings : json('null')
    }
  }
}

//create vnet integration for the app
resource appVnetIntegration 'Microsoft.Web/sites/networkConfig@2021-03-01' = if(!empty(vnetSubnetId)) {
  name: 'virtualNetwork'
  parent: webSite
  properties: {
    subnetResourceId: vnetSubnetId
    swiftSupported: true
  }
}

//outputs
@description('Resource Id of the app')
output websiteId string = webSite.id

output appServicePlanId string = asp.outputs.aspId
