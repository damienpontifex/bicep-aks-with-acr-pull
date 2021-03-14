targetScope = 'subscription'

param location string = deployment().location

var commonTags = {
  Client: 'Self'
  Environment: 'dev'
  ApplicationName: 'AksCluster'
}

resource sharedRg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'aks-shared'
  location: location
  tags: commonTags
}

resource clusterRg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'aks-cluster'
  location: location
  tags: commonTags
}

module network './network.bicep' = {
  name: 'network'
  scope: sharedRg
}

module cluster './cluster.bicep' = {
  name: 'cluster'
  scope: clusterRg
  params: {
    subnetId: network.outputs.subnetId
    logAnalyticsWorkspaceResourceID: network.outputs.logAnalyticsWorkspaceResourceID
    appGatewaySubnetId: network.outputs.appGatewaySubnetId
  }
}