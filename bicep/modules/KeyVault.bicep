@description('Specifies the name of the key vault.')
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'

@description('Specifies the SKU to use for the key vault.')
param keyVaultSku object = {
  name: 'standard'
  family: 'A'
}

@description('Specifies the Azure location where the resources should be created.')
param location string = resourceGroup().location

@description('Specifies the principal ID to the resources that reading of secrets is allowed.')
param readerPrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    sku: keyVaultSku
  }
}

@description('This is the built-in Key Vault Secrets User role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretsUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('This is the built-in Key Vault Secrets User role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultCertificatesOfficerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'a4417e6f-fecd-4de8-b567-7b0420556985'
}

resource secretRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, readerPrincipalId, keyVaultSecretsUserRoleDefinition.id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinition.id
    principalId: readerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource certificateRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, readerPrincipalId, keyVaultCertificatesOfficerRoleDefinition.id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultCertificatesOfficerRoleDefinition.id
    principalId: readerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultName string = keyVault.name
output keyVaultUrl string = keyVault.properties.vaultUri