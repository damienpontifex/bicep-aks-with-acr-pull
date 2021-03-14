param location string = resourceGroup().location
param tags object = resourceGroup().tags
param subnetId string
param developersAdGroupObjectId string = '4beb7555-b4ad-4328-b4e3-c8240fc17ee0'
param adminAdGroupObjectId string = '540bbc0e-e797-4219-8016-557c4a2bb770'
param logAnalyticsWorkspaceResourceID string
param appGatewaySubnetId string

var k8sVersion = '1.18.10'
var clusterName = 'mycluster'

resource ipPrefixes 'Microsoft.Network/publicIPPrefixes@2020-06-01' = {
  name: 'clusterIpPrefixes'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    prefixLength: 31
  }
}

resource cluster 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: k8sVersion
    dnsPrefix: 'mycluster-dns'
    enableRBAC: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      adminGroupObjectIDs: [
        adminAdGroupObjectId
      ]
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceResourceID
        }
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
            applicationGatewayName: 'myappgateway'
            subnetId: appGatewaySubnetId
            // subnetCIDR: '10.10.1.0/24'
        }
      }
    }
    podIdentityProfile: {
      enabled: true
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerProfile: {
        outboundIPPrefixes: {
          publicIPPrefixes: [
            {
              id: ipPrefixes.id
            }
          ]
        }
      }
    }
    agentPoolProfiles: [
      {
        name: 'linux1'
        orchestratorVersion: k8sVersion
        vnetSubnetID: subnetId
        count: 1
        mode: 'System'
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        tags: tags
      }
    ]
  }
}

var clusterRoleAssignments = [
  {
    adObjectId: developersAdGroupObjectId
    roleGuid: '7f6c6a51-bcf8-42ba-9220-52d62157d7db' // https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-rbac-reader
  }
  {
    adObjectId: developersAdGroupObjectId
    roleGuid: 'a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb' // https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-rbac-writer
  }
  {
    adObjectId: developersAdGroupObjectId
    roleGuid: '3498e952-d568-435e-9b2c-8d77e338d7f7' // https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-rbac-admin
  }
]

resource rbacAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for assignment in clusterRoleAssignments: {
  name: guid(cluster.id, developersAdGroupObjectId, assignment.roleGuid)
  scope: cluster
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleGuid)
    principalType: 'Group'
    principalId: assignment.adObjectId
  }
}]