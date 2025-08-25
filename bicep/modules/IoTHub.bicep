@description('Specifies the name of the IoT Hub.')
@minLength(3)
param iotHubName string

@description('Specifies whether the Iot Hub is located in Azure China.')
param isChina bool = false

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Specifies the IotHub SKU.')
param skuName string = 'F1'

@description('Specifies the number of provisioned IoT Hub units. Restricted to 1 unit for the F1 SKU. Can be set up to maximum number allowed for subscription.')
@minValue(1)
@maxValue(1)
param capacityUnits int = 1

@description('Specifies the primary certificate.')
param primaryCert string

@description('Specifies the secondary certificate.')
param secondaryCert string

var consumerGroupName = '${iotHubName}/events/devicetelemetry'
var partitionCount = skuName == 'F1' ? 2 : 4

resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: iotHubName
  location: location
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: partitionCount
      }
    }
    cloudToDevice: {
      defaultTtlAsIso8601: 'PT48H'
      maxDeliveryCount: 100
      feedback: {
        ttlAsIso8601: 'PT48H'
        lockDurationAsIso8601: 'PT60S'
        maxDeliveryCount: 100
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        ttlAsIso8601: 'PT1H'
        lockDurationAsIso8601: 'PT1M'
        maxDeliveryCount: 10
      }
    }
    routing: {
      endpoints: {
          serviceBusQueues: []
          serviceBusTopics: []
          eventHubs: []
          storageContainers: []
      }
      routes: []
      fallbackRoute: {
          name: '$fallback'
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
              'events'
          ]
          isEnabled: true
      }
    }
  }
  sku: {
    name: skuName
    capacity: capacityUnits
  }
}

resource consumerGroup 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2023-06-30' = {
  name: consumerGroupName
  properties: {
    name: 'devicetelemetry'
  }
  dependsOn: [
    iotHub
  ]
}

resource primaryCertificate 'Microsoft.Devices/IotHubs/certificates@2023-06-30' = {
  parent: iotHub
  name: 'intermediate-primary'
  properties: {
    certificate: primaryCert
    isVerified: true
  }
}

resource secondaryCertificate 'Microsoft.Devices/IotHubs/certificates@2023-06-30' = {
  parent: iotHub
  name: 'intermediate-secondary'
  properties: {
    certificate: secondaryCert
    isVerified: true
  }
}

var keyName = iotHub.listkeys().value[0].keyName
var keyValue = iotHub.listkeys().value[0].primaryKey

var rootDomain = isChina ? 'azure-devices.cn' : 'azure-devices.net'

var eventHubCompatibleEndpoint = iotHub.properties.eventHubEndpoints.events.endpoint
var eventHubCompatibleName = iotHub.properties.eventHubEndpoints.events.path

output hostName string = '${iotHubName}.${rootDomain}'
output iotHubConnectionString string = 'HostName=${iotHubName}.${rootDomain};SharedAccessKeyName=${keyName};SharedAccessKey=${keyValue}'
output eventHubConnectionString string = 'Endpoint=${eventHubCompatibleEndpoint};SharedAccessKeyName=${keyName};SharedAccessKey=${keyValue};EntityPath=${eventHubCompatibleName}'
