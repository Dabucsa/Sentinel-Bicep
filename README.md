# Microsoft Sentinel — Automated Deployment (Bicep)

> Replace `YOUR-GITHUB-ORG/YOUR-REPO` below after publishing this project to GitHub.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDabucsa%2FSentinel-Bicep%2Fmain%2Fazuredeploy.json)

> **v2.0** — Modular Bicep rewrite with 10+ free-tier connectors, workbooks, and automated Content Hub analytics rule activation.

> Handoff rápido: ver [GUIA-AVANCE.md](GUIA-AVANCE.md) para el resumen del avance, flujo recomendado y próximos pasos.

---

## What Gets Deployed

### Infrastructure
| Resource | Description |
|---|---|
| **Log Analytics Workspace** | PerGB2018 SKU, configurable retention (default 90 days) |
| **Microsoft Sentinel** | Onboarded via `onboardingStates` resource |

### Data Connectors (Free Tier)

| # | Connector | Kind | Cost | XDR Managed* |
|---|---|---|---|---|
| 1 | Azure Activity | Diagnostic Setting | Free | No |
| 2 | Office 365 (Exchange, SharePoint, Teams) | `Office365` | Free | No |
| 3 | Entra ID Protection | `AzureActiveDirectory` | Free (alerts) | Yes |
| 4 | Azure ATP (Defender for Identity) | `AzureAdvancedThreatProtection` | Free (alerts) | Yes |
| 5 | Microsoft Defender for Cloud | `AzureSecurityCenter` | Free (alerts) | No |
| 6 | Defender for Endpoint | `MicrosoftDefenderAdvancedThreatProtection` | Free (alerts) | Yes |
| 7 | Defender for Office 365 | `OfficeATP` | Free (alerts) | Yes |
| 8 | Cloud App Security (MCAS) | `MicrosoftCloudAppSecurity` | Free (alerts) | Yes |
| 9 | Microsoft Threat Intelligence (MDTI) | `MicrosoftThreatIntelligence` | Free | No |
| 10 | Threat Intelligence Platforms (TIP) | `ThreatIntelligence` | Free | No |

> **\*XDR Managed**: When `xdrIntegrated = true` (default), these connectors are skipped because XDR/Unified SOC portal manages them automatically.

### Workbooks
| Workbook | Description |
|---|---|
| Azure Activity | Top operations, failures, caller analysis |
| Office 365 | Exchange, SharePoint, Teams operations overview |
| Identity & Access | Entra ID Protection alerts, risky users |
| Microsoft Defender for Cloud | Security alerts, severity trends, MITRE tactics |
| Threat Intelligence | Indicator types, sources, IP/domain analysis |

### Analytics Rules (via PowerShell post-deploy)
The `Enable-ContentHubSolutions.ps1` script installs Content Hub solutions and activates their built-in analytics rule templates automatically.

### Applied Improvements
| Improvement | Applied change |
|---|---|
| Safer Deploy button guidance | Replaced the hardcoded old public repo URL with a publish-time placeholder |
| Less noisy workbook validation | Removed external workbook schema references from JSON templates |
| Better XDR alignment | Identity workbook now follows the same XDR skip logic as the identity connector |
| Stronger Content Hub automation | The script now skips already installed packages, uses more catalog metadata, and relaxes brittle template filtering |

---

## Prerequisites

1. **Azure subscription** with `Microsoft.SecurityInsights` resource provider registered
2. **Permissions**: `Microsoft Sentinel Contributor` + `Log Analytics Contributor` on the target resource group
3. **Azure CLI** with Bicep support (`az bicep version`) — or use the Deploy to Azure button
4. **PowerShell** with `Az.Accounts` module (for the Content Hub script)

---

## Quick Start

### Option 1: Deploy to Azure Button
Publish this repo to GitHub, replace the placeholder URL in this README, then use the button.

### Option 2: Azure CLI

```bash
# Login
az login

# Create resource group (if needed)
az group create -n rg-sentinel -l eastus

# Deploy with default parameters
az deployment group create \
  -g rg-sentinel \
  -f main.bicep \
  -p lawName=law-sentinel-prod

# Deploy with custom parameters
az deployment group create \
  -g rg-sentinel \
  -f main.bicep \
  -p lawName=law-sentinel-prod \
     retentionDays=180 \
     xdrIntegrated=false \
     enableOffice365=true
```

### Option 3: Using parameter file

```bash
az deployment group create \
  -g rg-sentinel \
  -f main.bicep \
  -p main.bicepparam
```

### Option 4: Preview changes before deploying

```powershell
.\scripts\Invoke-WhatIf.ps1 `
  -ResourceGroupName "rg-sentinel"

.\scripts\Invoke-WhatIf.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -Parameters @("lawName=law-sentinel-prod", "xdrIntegrated=false")
```

Use this before every real deployment to review creates, updates, and deletes.

### Option 5: Full workflow in one command

```powershell
.\scripts\Deploy-SentinelSolution.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod"

.\scripts\Deploy-SentinelSolution.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -Parameters @("xdrIntegrated=false")
```

This script runs build + what-if + deploy + smoke test in sequence.

---

## Post-Deploy: Enable Content Hub Analytics Rules

After the Bicep deployment completes, run the PowerShell script to install Content Hub solutions and activate built-in analytics rules:

```powershell
# Install required module (first time only)
Install-Module Az.Accounts -Force

# Login
Connect-AzAccount

# Dry run — see what would be activated
.\scripts\Enable-ContentHubSolutions.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -DryRun

# Execute — activate High and Medium severity rules
.\scripts\Enable-ContentHubSolutions.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -SeverityFilter @("High", "Medium")

# Activate ALL severity rules
.\scripts\Enable-ContentHubSolutions.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -SeverityFilter @("High", "Medium", "Low", "Informational")
```

### Content Hub Solutions Installed

| Solution | Content |
|---|---|
| Azure Activity | Analytics rules for Azure operations |
| Microsoft Entra ID | Sign-in and identity-based detections |
| Microsoft Defender for Cloud | Cloud security alert rules |
| Microsoft 365 | Office 365 threat detections |
| Microsoft Defender XDR | XDR multi-stage attack rules |
| Threat Intelligence | TI indicator matching rules |
| UEBA Essentials | User/entity behavior analytics |
| SOC Handbook | SOC operations best practices |
| Attacker Tools Threat Protection | Detection of common attacker tools |

---

## Post-Deploy: Smoke Test

After the deployment and optional analytics activation, run the smoke test to verify the core resources exist:

```powershell
# Validate workspace, Sentinel onboarding, connectors, and workbooks
.\scripts\Test-SentinelDeployment.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod"

# Validate with XDR-managed connectors enabled for checking
.\scripts\Test-SentinelDeployment.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -XdrIntegrated:$false
```

The smoke test checks:

- Log Analytics workspace exists
- Microsoft Sentinel onboarding state exists
- Expected data connectors exist
- Expected workbooks exist

---

## Suggested usage after deployment

Recommended order:

1. Run the full deployment script or deploy manually.
2. Run the smoke test if you skipped it during deployment.
3. Install Content Hub solutions and activate analytics rules.
4. Review rules in the portal and tune false positives.
5. Re-run the smoke test after major connector or workbook changes.

Example sequence:

```powershell
# 1. Full deployment
.\scripts\Deploy-SentinelSolution.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod"

# 2. Activate built-in analytics content
.\scripts\Enable-ContentHubSolutions.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -DryRun

.\scripts\Enable-ContentHubSolutions.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -SeverityFilter @("High", "Medium")

# 3. Re-check deployment state if needed
.\scripts\Test-SentinelDeployment.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod"
```

Operational note:

- Use [README.md](README.md#L106-L120) before changes.
- Use [README.md](README.md#L127-L160) after infra deploy to enable analytics content.
- Use [README.md](README.md#L179-L190) when you want a quick health check.

---

## Parameters Reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `lawName` | string | *(required)* | Name of the Log Analytics workspace |
| `location` | string | Resource group location | Azure region |
| `retentionDays` | int | `90` | Data retention (7-730 days) |
| `tenantId` | string | Current tenant | Azure AD tenant ID |
| `xdrIntegrated` | bool | `true` | Skip connectors managed by XDR |
| `enableAzureActivity` | bool | `true` | Azure Activity connector |
| `enableOffice365` | bool | `true` | Office 365 connector |
| `enableEntraIdProtection` | bool | `true` | Entra ID Protection connector |
| `enableAzureATP` | bool | `true` | Azure ATP connector |
| `enableDefenderForCloud` | bool | `true` | Defender for Cloud connector |
| `mdcSubscriptionId` | string | Current subscription | Subscription for MDC alerts |
| `enableDefenderForEndpoint` | bool | `true` | Defender for Endpoint connector |
| `enableDefenderForOffice365` | bool | `true` | Defender for Office 365 connector |
| `enableCloudAppSecurity` | bool | `true` | Cloud App Security connector |
| `enableMcasDiscoveryLogs` | bool | `false` | MCAS Discovery Logs (may incur cost) |
| `enableThreatIntelligence` | bool | `true` | MDTI feed connector |
| `enableTIPlatforms` | bool | `true` | TIP connector |
| `enableWorkbooks` | bool | `true` | Deploy Sentinel workbooks |

---

## Project Structure

```
├── main.bicep                          # Orchestrator — calls all modules
├── main.bicepparam                     # Default parameter values
├── azuredeploy.json                    # Compiled ARM (for Deploy to Azure button)
├── modules/
│   ├── workspace.bicep                 # Log Analytics + Sentinel onboarding
│   ├── connectors/
│   │   ├── azureActivity.bicep         # Azure Activity (subscription diag setting)
│   │   ├── office365.bicep             # Office 365
│   │   ├── entraIdProtection.bicep     # Entra ID Protection
│   │   ├── azureATP.bicep              # Azure ATP (Defender for Identity)
│   │   ├── defenderForCloud.bicep      # Defender for Cloud
│   │   ├── defenderForEndpoint.bicep   # Defender for Endpoint
│   │   ├── defenderForOffice365.bicep  # Defender for Office 365
│   │   ├── cloudAppSecurity.bicep      # Cloud App Security
│   │   ├── threatIntelligence.bicep    # Microsoft Threat Intelligence
│   │   └── microsoftTI.bicep           # Threat Intelligence Platforms
│   └── workbooks/
│       ├── azureActivity.bicep
│       ├── office365.bicep
│       ├── identityProtection.bicep
│       ├── defenderForCloud.bicep
│       ├── threatIntelligence.bicep
│       └── templates/                  # Workbook JSON gallery templates
│           ├── azureActivity.json
│           ├── office365.json
│           ├── identityProtection.json
│           ├── defenderForCloud.json
│           └── threatIntelligence.json
├── scripts/
│   ├── Deploy-SentinelSolution.ps1     # Full workflow: build + what-if + deploy + smoke test
│   ├── Enable-ContentHubSolutions.ps1  # Post-deploy: install solutions + activate rules
│   ├── Invoke-WhatIf.ps1               # Preview deployment changes safely
│   ├── Test-SentinelDeployment.ps1     # Smoke test after deployment
│   └── Export-AnalyticsRules.ps1       # Utility: export existing rules to JSON
└── README.md
```

---

## Utility: Export Existing Rules

To backup or version-control your existing analytics rules:

```powershell
.\scripts\Export-AnalyticsRules.ps1 `
  -ResourceGroupName "rg-sentinel" `
  -WorkspaceName "law-sentinel-prod" `
  -OutputPath "./exported-rules"
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                        │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │          Log Analytics Workspace (PerGB2018)             │  │
│  │                                                           │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │         Microsoft Sentinel (onboarded)            │    │  │
│  │  │                                                    │    │  │
│  │  │  Data Connectors:                                  │    │  │
│  │  │  • Azure Activity (Diagnostic Setting)             │    │  │
│  │  │  • Office 365 (Exchange, SharePoint, Teams)        │    │  │
│  │  │  • Entra ID Protection *                           │    │  │
│  │  │  • Azure ATP (Defender for Identity) *             │    │  │
│  │  │  • Defender for Cloud                              │    │  │
│  │  │  • Defender for Endpoint *                         │    │  │
│  │  │  • Defender for Office 365 *                       │    │  │
│  │  │  • Cloud App Security *                            │    │  │
│  │  │  • Microsoft Threat Intelligence (MDTI)            │    │  │
│  │  │  • Threat Intelligence Platforms (TIP)             │    │  │
│  │  │                                                    │    │  │
│  │  │  * Skipped when xdrIntegrated = true               │    │  │
│  │  │                                                    │    │  │
│  │  │  Workbooks: Activity, O365, Identity, MDC, TI      │    │  │
│  │  │                                                    │    │  │
│  │  │  Analytics Rules: via Content Hub script            │    │  │
│  │  └──────────────────────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## Generating the ARM Template (for Deploy to Azure button)

If you modify the Bicep files, regenerate the compiled ARM template:

```bash
az bicep build -f main.bicep --outfile azuredeploy.json
```

Then commit `azuredeploy.json` to the repo.

---

## License

MIT
