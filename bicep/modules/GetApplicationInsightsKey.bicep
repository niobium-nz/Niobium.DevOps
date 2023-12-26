@description('Specifies the name of the application insights.')
param applicationInsightsName string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey