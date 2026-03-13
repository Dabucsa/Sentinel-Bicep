using 'main.bicep'

// ===========================================================================
// Parameter values — adjust to your environment
// ===========================================================================

param lawName = 'law-sentinel-prod'
param retentionDays = 90

// Set to false if NOT using XDR Unified SOC portal
// When true, connectors managed by XDR are skipped (Entra ID, ATP, MDE, MDO, MCAS)
param xdrIntegrated = true

// --- Connector toggles ---
param enableAzureActivity = true
param enableOffice365 = true
param enableEntraIdProtection = true
param enableAzureATP = true
param enableDefenderForCloud = true
param enableDefenderForEndpoint = true
param enableDefenderForOffice365 = true
param enableCloudAppSecurity = true
param enableMcasDiscoveryLogs = false
param enableThreatIntelligence = true
param enableTIPlatforms = true

// --- Workbooks ---
param enableWorkbooks = true
