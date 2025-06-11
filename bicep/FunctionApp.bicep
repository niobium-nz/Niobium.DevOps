@description('The name of the function app that you wish to create.')
param appName string = 'fnapp${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The dotnet runtime version supported by the function app.')
@allowed([
  '6'
  '7'
  '8'
])
param dotnetVersion string = '8'

@description('Optional custom domain names.')
param customDomainNames array = []

@description('Optional enable custom domain name managed SSL certificate.')
param customDomainNameManagedCertificate bool = false

@description('Whether to deploy KeyVault.')
param enableKeyVault bool = false

@description('Whether to enable staging deployment slot.')
param enableStagingSlot bool = false

@description('Allowed CORS origins.')
param allowedOrigins string = ''

@description('Whether to enable Access-Control-Allow-Credentials on CORS.')
param corsSupportCredentials bool = false

var inputFuncAppName = appName
var appNamePrefix = endsWith(appName, 'Func') ? appName : '${appName}Func'
var inputHostingPlanName = '${appNamePrefix}Plan'
var inputApplicationInsightsName = '${appNamePrefix}Insights'
var inputLogAnalyticsWorkspaceName = '${appNamePrefix}Logs'
var inputStorageAccountName = toLower('${appNamePrefix}Store')
var inputKeyVaultName = '${appNamePrefix}Vault'
var dotnetVersionParam = 'v${dotnetVersion}.0'
var allowedOriginsArray = empty(allowedOrigins) ? [] : split(allowedOrigins, ',')
var corsSupportCredentialsValue = empty(allowedOriginsArray) ? false : corsSupportCredentials

module storageAccount 'modules/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: location
    storageAccountName: inputStorageAccountName
    storageAccountSku: storageAccountType
    allowedOrigins: allowedOrigins
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: inputHostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
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
        allowedOrigins: allowedOriginsArray
        supportCredentials: corsSupportCredentialsValue
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: dotnetVersionParam
      use32BitWorkerProcess: false
    }
    httpsOnly: true
  }
}

resource functionAppStagingSlot 'Microsoft.Web/sites/slots@2024-04-01' = if (enableStagingSlot) {
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
      cors:{
        allowedOrigins: allowedOriginsArray
        supportCredentials: corsSupportCredentialsValue
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: dotnetVersionParam
      use32BitWorkerProcess: false
    }
    httpsOnly: true
  }
}

resource customDomain 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = [for customDomainName in customDomainNames: {
  name: customDomainName
  parent: functionApp
  properties: {
    customHostNameDnsRecordType: 'CName'
    hostNameType: 'Verified'
    sslState: 'SniEnabled'
  }
}]

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

// role assignment on resource group level is not support, so manual intervene is needed.
resource customDomainScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = [for customDomainName in customDomainNames: if (customDomainNameManagedCertificate) {
  name: 'customDomainScript${customDomainName}'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    customDomain
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
        value: customDomainName
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
    ]
  }
}]

output functionAppName string = functionApp.name
output functionAppContentShareName string = toLower(functionApp.name)
output functionAppHostname string = functionApp.properties.defaultHostName
output functionAppPrincipalId string = functionApp.identity.principalId
output hostingPlanName string = hostingPlan.name
output storageAccountName string = storageAccount.name
output storageAccountConnectionString string = storageAccount.outputs.storageAccountConnectionString1
output applicationInsightsName string = applicationInsights.name
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output keyVaultName string = enableKeyVault ? keyVault.outputs.keyVaultName : ''
output keyVaultUrl string = enableKeyVault ? keyVault.outputs.keyVaultUrl : ''
