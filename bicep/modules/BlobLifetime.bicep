@description('Specifies the name of the storage account.')
param storageAccountName string

@description('Specifies days after last access time before moving to cold tier.')
param daysToCold int

@description('Specifies days after last access time before moving to archive tier.')
param daysToArchive int

@description('Specifies days after last access time before removing.')
param daysToRemove int

@description('Specifies the tag to match for cost optimization.')
param tagToMatch string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}
resource lifetimePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2022-09-01' = {
  name: 'costOptimization'
  parent: storageAccount
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'move-to-cool'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCold: {
                  daysAfterLastAccessTimeGreaterThan: daysToCold
                }
                tierToArchive: {
                  daysAfterLastAccessTimeGreaterThan: daysToArchive
                }
                delete: {
                  daysAfterLastAccessTimeGreaterThan: daysToRemove
                }
              }
            }
            filters: {
              blobIndexMatch: [
                {
                  name: tagToMatch
                  op: '=='
                  value: 'true'
                }
              ]
              blobTypes: [
                'blockBlob'
              ]
            }
          }
        }
      ]
    }
  }
}