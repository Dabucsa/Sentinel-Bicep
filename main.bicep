// ============================================================================
// Main Orchestrator: Microsoft Sentinel Automated Deployment
// Version: 2.0.0
// Description: Deploys a complete Sentinel environment with workspace,
//              free-tier data connectors, and workbooks.
//
// Usage:
//   az deployment group create \
//     -g <resource-group> \
//     -f main.bicep \
//     -p lawName=<workspace-name>
// ============================================================================

targetScope = 'resourceGroup'

// ===========================================================================
// Parameters
// ===========================================================================

@description('Name of the Log Analytics workspace to create')
param lawName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Data retention in days (7-730)')
@minValue(7)
@maxValue(730)
param retentionDays int = 90

@description('Azure AD tenant ID')
param tenantId string = tenant().tenantId

@description('When true, skips connectors managed automatically by XDR/Unified SOC (Entra ID Protection, Azure ATP, MDE, MDO, MCAS)')
param xdrIntegrated bool = true

// --- Connector toggles (all default: true) ---

@description('Enable Azure Activity connector')
param enableAzureActivity bool = true

@description('Name for the subscription diagnostic setting')
param diagnosticSettingName string = 'sentinelActivityLogs'

@description('Enable Office 365 connector (Exchange, SharePoint, Teams)')
param enableOffice365 bool = true

@description('Enable Entra ID Protection connector')
param enableEntraIdProtection bool = true

@description('Enable Azure ATP (Defender for Identity) connector')
param enableAzureATP bool = true

@description('Enable Defender for Cloud connector')
param enableDefenderForCloud bool = true

@description('Subscription ID for Defender for Cloud alerts')
param mdcSubscriptionId string = subscription().subscriptionId

@description('Enable Defender for Endpoint connector')
param enableDefenderForEndpoint bool = true

@description('Enable Defender for Office 365 connector')
param enableDefenderForOffice365 bool = true

@description('Enable Cloud App Security connector')
param enableCloudAppSecurity bool = true

@description('Enable Cloud App Security Discovery Logs (may incur ingestion cost)')
param enableMcasDiscoveryLogs bool = false

@description('Enable Microsoft Threat Intelligence (MDTI) feed connector')
param enableThreatIntelligence bool = true

@description('Enable Threat Intelligence Platforms (TIP) connector')
param enableTIPlatforms bool = true

// --- Workbook toggle ---

@description('Deploy Sentinel workbooks for each enabled connector')
param enableWorkbooks bool = true

// ===========================================================================
// Computed: skip connectors that XDR manages
// ===========================================================================

var skipXdrManaged = xdrIntegrated

// ===========================================================================
// Module: Log Analytics Workspace + Sentinel Onboarding
// ===========================================================================

module workspace 'modules/workspace.bicep' = {
  name: 'deploy-workspace'
  params: {
    lawName: lawName
    location: location
    retentionDays: retentionDays
  }
}

// ===========================================================================
// Module: Azure Activity (subscription diagnostic setting)
// ===========================================================================

module connAzureActivity 'modules/connectors/azureActivity.bicep' = if (enableAzureActivity) {
  name: 'deploy-connector-azureActivity'
  scope: subscription()
  params: {
    workspaceId: workspace.outputs.workspaceId
    diagnosticSettingName: diagnosticSettingName
  }
}

// ===========================================================================
// Module: Office 365 (Exchange, SharePoint, Teams)
// ===========================================================================

module connOffice365 'modules/connectors/office365.bicep' = if (enableOffice365) {
  name: 'deploy-connector-office365'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Module: Entra ID Protection — skipped if XDR integrated
// ===========================================================================

module connEntraId 'modules/connectors/entraIdProtection.bicep' = if (enableEntraIdProtection && !skipXdrManaged) {
  name: 'deploy-connector-entraIdProtection'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Module: Azure ATP (Defender for Identity) — skipped if XDR integrated
// ===========================================================================

module connAzureATP 'modules/connectors/azureATP.bicep' = if (enableAzureATP && !skipXdrManaged) {
  name: 'deploy-connector-azureATP'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Module: Defender for Cloud
// ===========================================================================

module connDefenderCloud 'modules/connectors/defenderForCloud.bicep' = if (enableDefenderForCloud) {
  name: 'deploy-connector-defenderForCloud'
  params: {
    workspaceName: workspace.outputs.workspaceName
    mdcSubscriptionId: mdcSubscriptionId
  }
}

// ===========================================================================
// Module: Defender for Endpoint — skipped if XDR integrated
// ===========================================================================

module connDefenderEndpoint 'modules/connectors/defenderForEndpoint.bicep' = if (enableDefenderForEndpoint && !skipXdrManaged) {
  name: 'deploy-connector-defenderForEndpoint'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Module: Defender for Office 365 — skipped if XDR integrated
// ===========================================================================

module connDefenderOffice 'modules/connectors/defenderForOffice365.bicep' = if (enableDefenderForOffice365 && !skipXdrManaged) {
  name: 'deploy-connector-defenderForOffice365'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Module: Cloud App Security — skipped if XDR integrated
// ===========================================================================

module connMcas 'modules/connectors/cloudAppSecurity.bicep' = if (enableCloudAppSecurity && !skipXdrManaged) {
  name: 'deploy-connector-cloudAppSecurity'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
    enableDiscoveryLogs: enableMcasDiscoveryLogs
  }
}

// ===========================================================================
// Module: Microsoft Threat Intelligence (MDTI feed)
// ===========================================================================

module connThreatIntel 'modules/connectors/threatIntelligence.bicep' = if (enableThreatIntelligence) {
  name: 'deploy-connector-threatIntelligence'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Module: Threat Intelligence Platforms (TIP)
// ===========================================================================

module connTIP 'modules/connectors/microsoftTI.bicep' = if (enableTIPlatforms) {
  name: 'deploy-connector-microsoftTI'
  params: {
    workspaceName: workspace.outputs.workspaceName
    tenantId: tenantId
  }
}

// ===========================================================================
// Workbooks
// ===========================================================================

module wbAzureActivity 'modules/workbooks/azureActivity.bicep' = if (enableWorkbooks && enableAzureActivity) {
  name: 'deploy-workbook-azureActivity'
  params: {
    workspaceId: workspace.outputs.workspaceId
    location: location
  }
}

module wbOffice365 'modules/workbooks/office365.bicep' = if (enableWorkbooks && enableOffice365) {
  name: 'deploy-workbook-office365'
  params: {
    workspaceId: workspace.outputs.workspaceId
    location: location
  }
}

module wbIdentity 'modules/workbooks/identityProtection.bicep' = if (enableWorkbooks && enableEntraIdProtection && !skipXdrManaged) {
  name: 'deploy-workbook-identityProtection'
  params: {
    workspaceId: workspace.outputs.workspaceId
    location: location
  }
}

module wbDefenderCloud 'modules/workbooks/defenderForCloud.bicep' = if (enableWorkbooks && enableDefenderForCloud) {
  name: 'deploy-workbook-defenderForCloud'
  params: {
    workspaceId: workspace.outputs.workspaceId
    location: location
  }
}

module wbThreatIntel 'modules/workbooks/threatIntelligence.bicep' = if (enableWorkbooks && enableThreatIntelligence) {
  name: 'deploy-workbook-threatIntelligence'
  params: {
    workspaceId: workspace.outputs.workspaceId
    location: location
  }
}

// ===========================================================================
// Outputs
// ===========================================================================

@description('Resource ID of the deployed Log Analytics workspace')
output workspaceId string = workspace.outputs.workspaceId

@description('Name of the deployed workspace')
output workspaceName string = workspace.outputs.workspaceName

@description('XDR integration mode — connectors skipped when true')
output xdrIntegratedMode bool = xdrIntegrated

@description('Summary of enabled connectors')
output enabledConnectors object = {
  azureActivity: enableAzureActivity
  office365: enableOffice365
  entraIdProtection: enableEntraIdProtection && !skipXdrManaged
  azureATP: enableAzureATP && !skipXdrManaged
  defenderForCloud: enableDefenderForCloud
  defenderForEndpoint: enableDefenderForEndpoint && !skipXdrManaged
  defenderForOffice365: enableDefenderForOffice365 && !skipXdrManaged
  cloudAppSecurity: enableCloudAppSecurity && !skipXdrManaged
  threatIntelligence: enableThreatIntelligence
  tipPlatforms: enableTIPlatforms
}
