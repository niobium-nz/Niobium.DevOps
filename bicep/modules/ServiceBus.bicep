@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Queues')
param serviceBusQueueNames array = []

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Specifies the SKU to use for the Service Bus namespace.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param serviceBusSku string = 'Basic'

@description('Specifies the principal ID to the resources that owns the data of this Service Bus namespace.')
param dataOwnerPrincipalId string = ''
var dataOwnerPrincipalIdValue = empty(dataOwnerPrincipalId) ? 'dummy' : dataOwnerPrincipalId

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: serviceBusSku
    tier: serviceBusSku
  }
  properties: {}
}

resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2023-01-01-preview' = [for serviceBusQueueName in serviceBusQueueNames: {
  parent: serviceBusNamespace
  name: serviceBusQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    enablePartitioning: false
    enableExpress: false
  }
}]

resource sendAuthorizationRules 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2023-01-01-preview' = [for i in range(0, length(serviceBusQueues)): {
  name: '${serviceBusQueues[i].name}-2'
  parent: serviceBusQueues[i]
  properties: {
    rights: [
      'Send'
    ]
  }
}]

resource listenAuthorizationRules 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2023-01-01-preview' = [for i in range(0, length(serviceBusQueues)): {
  name: '${serviceBusQueues[i].name}-8'
  parent: serviceBusQueues[i]
  properties: {
    rights: [
      'Listen'
    ]
  }
}]

@description('This is the built-in Azure Service Bus Data Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource serviceBusDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '090c5cfd-751d-490a-894a-3ce6f1109419'
}

resource serviceBusDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (dataOwnerPrincipalIdValue != 'dummy') {
  name: guid(serviceBusNamespace.id, dataOwnerPrincipalId, serviceBusDataOwnerRoleDefinition.id)
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinition.id
    principalId: dataOwnerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output fullyQualifiedNamespace string = '${serviceBusNamespaceName}.servicebus.windows.net'
