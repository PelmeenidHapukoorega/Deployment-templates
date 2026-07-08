@description('Naming prefix for resources')
param prefix string

@description('Region to deploy into')
param location string

@description('Log retention period in days')
param retentionInDays int = 30

@description('SKU for the log analytics workspace')
param sku string = 'PerGB2018'

@description('Email for alert notifications. Leave empty to skip creation')
param alertEmail string = ''

@description('List of resource IDs to create CPU/memory alerts against')
param alertTargets array = []

@description('CPU alert for each alert target')
param enableCpuAlert bool = true

@description('Memory alert for each alert target')
param enableMemoryAlert bool = true

@description('CPU % threshold for alert trigger')
param cpuThreshold int = 80

@description('Available memory threshold (measured in bytes) for alert trigger')
param memoryThreshold int = 500000000

@description('Tags to apply to all resources')
param tags object = {}


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${prefix}-law'
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
  }
  tags: tags
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (!empty(alertEmail)) {
  name: '${prefix}-action-group'
  location: 'global'
  properties: {
    groupShortName: take('${prefix}ag', 12)
    enabled: true
    emailReceivers: [
      {
        name: 'primary'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ] 
  }
  tags: tags
}

resource cpuAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = [for (targetId, i) in (enableCpuAlert && !empty(alertEmail) ? alertTargets : []): {
  name: '${prefix}-cpu-alert-${i}'
  location: 'global'
  properties: {
    severity: 3
    enabled: true
    scopes: [targetId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'HighCPU'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: cpuThreshold
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ] 
  }
  tags: tags
}]

resource memoryAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = [for (targetId, i) in (enableMemoryAlert && !empty(alertEmail) ? alertTargets : []): {
  name: '${prefix}-memory-alert-${i}'
  location: 'global'
  properties: {
    severity: 3
    enabled:true
    scopes: [targetId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'LowMemory'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Available Memory Bytes'
          operator: 'LessThan'
          threshold: memoryThreshold
          timeAggregation: 'Average'
        }
      ] 
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ] 
  }
  tags: tags
}]


output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
output actionGroupId string = !empty(alertEmail) ? actionGroup.id : ''
