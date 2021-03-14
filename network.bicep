param location string = resourceGroup().location
param tags object = resourceGroup().tags

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'aks-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'first'
        properties: {
          addressPrefix: '10.10.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'appGateway'
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'firstsubnet-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowAzureFrontDoorBackend'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureFrontDoor.Backend'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          description: 'Allow access only to Azure Front Door for external traffic'
        }
      }
      {
        name: 'AllowApplicationGateway'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Inbound'
          description: 'Allow access only to Azure Application Gateway for external traffic'
        }
      }
    ]
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: 'aksregistry${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {}
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: 'aks-workspace-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'first')
output appGatewaySubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'appGateway')
output logAnalyticsWorkspaceResourceID string = logAnalytics.id