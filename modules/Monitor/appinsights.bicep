// Bicep module to deploy app insights resource
@description('Azure region in which the resource will be deployed')
param resourceLocation string

@description('App insights block')
param appInsightsValues object /*= { 
  {
    namePrefix: ''                      //string
    kind: ''                      //string
    applicationType: ''           //string
    newWorkspace:
    workspaceRG: ''
    workspace: {
      name:
      sku:
    }
  }
}
*/

resource existingLogWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if(!(appInsightsValues.newWorkspace)) {
  name: appInsightsValues.workspace.name
  scope: !empty(appInsightsValues.workspaceRG) ? resourceGroup(appInsightsValues.workspaceRG) : resourceGroup()
}

module newLogWorkspace 'loganalyticsworkspace.bicep' = if(appInsightsValues.newWorkspace && !empty(appInsightsValues.workspace)) {
  name: 'logAnalyticsWorkspace'
  params: {
    resourceLocation: resourceLocation
    logAnalyticsWorkspaceValues: appInsightsValues.workspace
  }
}

//create app insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' =  {
  name: '${appInsightsValues.namePrefix}-appi'
  location: resourceLocation
  kind: appInsightsValues.kind
  properties: {
    Application_Type: appInsightsValues.applicationType
    WorkspaceResourceId: (appInsightsValues.newWorkspace) ? newLogWorkspace.outputs.resourceId : existingLogWorkspace.id
  }
}

//outputs
@description('Resource Id of the application insights')
output appInsightsId string = appInsights.id

@description('Connection string of the application insight')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('Instrumentation key of the application insight')
output appInsightsKey string = appInsights.properties.InstrumentationKey

@description('')
output logAnalyticsWorkspaceId string = newLogWorkspace.outputs.resourceId
