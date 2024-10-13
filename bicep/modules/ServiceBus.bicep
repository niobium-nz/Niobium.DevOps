@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Queue')
param serviceBusQueueName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Specifies the SKU to use for the Service Bus namespace.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param serviceBusSku string = 'Basic'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: serviceBusSku
    tier: serviceBusSku
  }
  properties: {}
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2023-01-01-preview' = {
  parent: serviceBusNamespace
  name: serviceBusQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 256
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource sendAuthorizationRules 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2023-01-01-preview' = {
  name: '${serviceBusQueueName}-2'
  parent: serviceBusQueue
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource listenAuthorizationRules 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2023-01-01-preview' = {
  name: '${serviceBusQueueName}-8'
  parent: serviceBusQueue
  properties: {
    rights: [
      'Listen'
    ]
  }
}

output fullyQualifiedNamespace string = '${serviceBusNamespaceName}.servicebus.windows.net'
