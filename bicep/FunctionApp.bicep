@description('The name of the function app that you wish to create.')
param appNamePrefix string = 'fnapp${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The language worker runtime to load in the function app.')
@allowed([
  'dotnet'
  'dotnet-isolated'
  'node'
  'java'
])
param runtime string = 'dotnet-isolated'

@description('Optional custom domain name.')
param customDomainName string = ''

@description('Optional enable custom domain name managed SSL certificate.')
param customDomainNameManagedCertificate bool = false

@description('Whether to deploy KeyVault.')
param enableKeyVault bool = false

@description('Whether to enable staging deployment slot.')
param enableStagingSlot bool = false

@description('Allowed CORS origins.')
param allowedOrigins array = []

var inputFuncAppName = '${appNamePrefix}Func'
var inputHostingPlanName = '${appNamePrefix}Plan'
var inputApplicationInsightsName = '${appNamePrefix}Insights'
var inputLogAnalyticsWorkspaceName = '${appNamePrefix}Logs'
var inputStorageAccountName = toLower('${appNamePrefix}Store')
var inputKeyVaultName = '${appNamePrefix}Vault'
var functionWorkerRuntime = runtime


module storageAccount 'modules/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: location
    storageAccountName: inputStorageAccountName
    storageAccountSku: storageAccountType
    allowedOrigins: allowedOrigins
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: inputHostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: inputFuncAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      cors:{
        allowedOrigins: allowedOrigins
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.outputs.storageAccountConnectionString1
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccount.outputs.storageAccountConnectionString1
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(inputFuncAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource functionAppStagingSlot 'Microsoft.Web/sites/slots@2022-09-01' = if (enableStagingSlot) {
  parent: functionApp
  name: 'staging'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.outputs.storageAccountConnectionString1
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccount.outputs.storageAccountConnectionString1
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${toLower(inputFuncAppName)}-staging'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

var customDomainNameValue = empty(customDomainName) ? 'dummy' : customDomainName
resource customDomain 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = if (customDomainNameValue != 'dummy') {
  name: customDomainNameValue
  parent: functionApp
  properties: {
    customHostNameDnsRecordType: 'CName'
    hostNameType: 'Verified'
    sslState: 'Disabled'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: inputLogAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
	  dailyQuotaGb: 1
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: inputApplicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    Flow_Type: 'Bluefield'
  }
}

module keyVault 'modules/KeyVault.bicep' = if (enableKeyVault) {
  name: 'keyVault'
  params: {
    location: location
    keyVaultName: inputKeyVaultName
    readerPrincipalId: functionApp.identity.principalId
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'DeploymentScript'
  location: location
}

resource scriptContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // This is the Website Contributor role, which is the minimum role permission we can give. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#website-contributor
  name: 'de139f84-1756-47ae-9be6-808fbbe84772'
}

resource scriptRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: functionApp
  name: guid(resourceGroup().id, managedIdentity.id, scriptContributorRoleDefinition.id)
  properties: {
    roleDefinitionId: scriptContributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (customDomainNameManagedCertificate && customDomainNameValue != 'dummy') {
  name: 'deploymentScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    scriptRoleAssignment
  ]
  properties: {
    azPowerShellVersion: '10.4.1'
    scriptContent: loadTextContent('../scripts/enable-webapp-managed-certificate.ps1')
    retentionInterval: 'PT4H'
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'FunctionAppName'
        value: functionApp.name
      }
      {
        name: 'CustomDomainName'
        value: customDomainNameValue
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
    ]
  }
}

output functionAppName string = functionApp.name
output functionAppHostname string = functionApp.properties.defaultHostName
output hostingPlanName string = hostingPlan.name
output storageAccountName string = storageAccount.name
output storageAccountConnectionString string = storageAccount.outputs.storageAccountConnectionString1
output applicationInsightsName string = applicationInsights.name
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUrl string = keyVault.outputs.keyVaultUrl