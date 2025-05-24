@description('Specifies the name of the storage account.')
param storageAccountName string = 'niobiumbillingdb'

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
param allowedOrigins string = ''

@description('Specifies the principal ID to the resources that manages this storage account.')
param contributorPrincipalId string = '72e62bcd-4a67-4d7a-b21b-583c40582220'
var contributorPrincipalIdValue = empty(contributorPrincipalId) ? 'dummy' : contributorPrincipalId
var allowedOriginsArray = split(allowedOrigins, ',')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
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

@description('This is the built-in Storage Account Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource storageAccountContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
}

@description('This is the built-in Storage Blob Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource storageBlobContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

@description('This is the built-in Storage Queue Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource storageQueueContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
}

@description('This is the built-in Storage Table Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-contributor')
resource storageTableContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
}

resource accountContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (contributorPrincipalIdValue != 'dummy') {
  name: guid(storageAccount.id, contributorPrincipalId, storageAccountContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageAccountContributorRoleDefinition.id
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource blobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (contributorPrincipalIdValue != 'dummy') {
  name: guid(storageAccount.id, contributorPrincipalId, storageBlobContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobContributorRoleDefinition.id
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource queueContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (contributorPrincipalIdValue != 'dummy') {
  name: guid(storageAccount.id, contributorPrincipalId, storageQueueContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageQueueContributorRoleDefinition.id
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource tableContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (contributorPrincipalIdValue != 'dummy') {
  name: guid(storageAccount.id, contributorPrincipalId, storageTableContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageTableContributorRoleDefinition.id
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageAccountTable 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = if (!empty(allowedOriginsArray) && !contains(allowedOriginsArray, '')) {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: allowedOriginsArray
          maxAgeInSeconds: 0
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'DELETE'
            'GET'
            'HEAD'
            'MERGE'
            'POST'
            'OPTIONS'
            'PUT'
          ]
          exposedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
}

resource storageAccountQueue 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = if (!empty(allowedOriginsArray) && !contains(allowedOriginsArray, '')) {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: allowedOriginsArray
          maxAgeInSeconds: 0
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'DELETE'
            'GET'
            'HEAD'
            'MERGE'
            'POST'
            'OPTIONS'
            'PUT'
          ]
          exposedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
}

resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = if (!empty(allowedOriginsArray) && !contains(allowedOriginsArray, '')) {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: allowedOriginsArray
          maxAgeInSeconds: 0
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'DELETE'
            'GET'
            'HEAD'
            'MERGE'
            'POST'
            'OPTIONS'
            'PUT'
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
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output tableEndpoint string = storageAccount.properties.primaryEndpoints.table
output queueEndpoint string = storageAccount.properties.primaryEndpoints.queue
output blobFQDN string = replace(replace(storageAccount.properties.primaryEndpoints.blob, 'https://', ''), '/', '')
output tableFQDN string = replace(replace(storageAccount.properties.primaryEndpoints.table, 'https://', ''), '/', '')
output queueFQDN string = replace(replace(storageAccount.properties.primaryEndpoints.queue, 'https://', ''), '/', '')
