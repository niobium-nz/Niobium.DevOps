@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Specifies the principal ID to the resources that owns the data of this Service Bus namespace.')
param dataOwnerPrincipalId string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

@description('This is the built-in Azure Service Bus Data Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource serviceBusDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '090c5cfd-751d-490a-894a-3ce6f1109419'
}

resource serviceBusDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespace.id, dataOwnerPrincipalId, serviceBusDataOwnerRoleDefinition.id)
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinition.id
    principalId: dataOwnerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output fullyQualifiedNamespace string = '${serviceBusNamespaceName}.servicebus.windows.net'
