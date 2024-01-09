@description('Specifies the name of the storage account.')
param storageAccountName string = 'stor${uniqueString(resourceGroup().id)}'

@description('Specifies the SKU to use for the storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountSku string = 'Standard_LRS'

@description('Specifies the Azure location where the resources should be created.')
param location string = resourceGroup().location

@description('Allowed CORS origins.')
param allowedOrigins array = []

@description('Specifies the principal ID to the resources that manages this storage account.')
param contributorPrincipalId string = ''
var contributorPrincipalIdValue = empty(contributorPrincipalId) ? 'dummy' : contributorPrincipalId

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true    
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    accessTier: 'Hot'
  }
}

@description('This is the built-in Key Vault Secrets User role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource storageAccountContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (contributorPrincipalIdValue != 'dummy') {
  name: guid(storageAccount.id, contributorPrincipalId, storageAccountContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageAccountContributorRoleDefinition.id
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageAccountTable 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' = if (!(empty(allowedOrigins))) {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: allowedOrigins
          maxAgeInSeconds: 0
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'OPTIONS'
            'HEAD'
            'GET'
          ]
          exposedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
}

resource storageAccountQueue 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' = if (!(empty(allowedOrigins))) {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: allowedOrigins
          maxAgeInSeconds: 0
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'OPTIONS'
            'HEAD'
            'GET'
            'PUT'
            'POST'
          ]
          exposedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
}

resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = if (!(empty(allowedOrigins))) {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: allowedOrigins
          maxAgeInSeconds: 0
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'OPTIONS'
            'HEAD'
            'GET'
            'PUT'
            'POST'
            'DELETE'
            'PATCH'
          ]
          exposedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
}

var storageConnstr1 = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
var storageConnstr2 = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[1].value}'

output storageAccountConnectionString1 string = storageConnstr1
output storageAccountConnectionString2 string = storageConnstr2
