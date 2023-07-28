param functionName string
param slotName string

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionName

  resource slot 'slots' existing = {
      name: slotName
  }
}