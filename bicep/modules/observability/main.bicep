@description('Naming prefix for resources')
param prefix string

@description('Region to deploy into')
param location string

@description('Log retention period in days')
param retentionInDays int = 30

@description('SKU for the log analytics workspace')
param sku string = 'PerGB2018'

@description('List of resource IDs to send diagnostic logs/metrics to the workspace')
param diagnosticTargets array = []

@description('Optional log category grouping in diagnostic settings. Doesnt work with VMs, set to false then')
param enableLogCategory bool = true

@description('Email for alert notifications. Leave empty to skip creation')
param alertEmail string = ''

@description('List of resource IDs to create CPU/memory alerts against')
param alertTargets array = []

@description('CPU alert for each alert target')
param enableMemoryAlert bool = true

@description('CPU % threshold for alert trigger')
param cpuThreshold int = 80

@description('Available memory threshold (measured in bytes) for alert trigger')
param memoryThreshold int = 500000000

@description('Tags to apply to all resources')
param tags object = {}
