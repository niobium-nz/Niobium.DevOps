@description('Specifies the name of the storage account.')
param storageAccountName string

@description('Specifies days after last access time before moving to cold tier.')
param daysToCold int

@description('Specifies days after last access time before moving to archive tier.')
param daysToArchive int

@description('Specifies days after last access time before removing.')
param daysToRemove int

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
          name: 'move-to-cold'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCold: {
                  daysAfterLastAccessTimeGreaterThan: daysToCold
                }
              }
            }
            filters: {
              blobIndexMatch: [
                {
                  name: 'toCold'
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
        {
          enabled: true
          name: 'move-to-archive'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterLastAccessTimeGreaterThan: daysToArchive
                }
              }
            }
            filters: {
              blobIndexMatch: [
                {
                  name: 'toArchive'
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
        {
          enabled: true
          name: 'to-delete'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                delete: {
                  daysAfterLastAccessTimeGreaterThan: daysToRemove
                }
              }
            }
            filters: {
              blobIndexMatch: [
                {
                  name: 'toDelete'
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