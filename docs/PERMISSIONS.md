# Permissions and service dependencies

Use a dedicated administrative account, just-in-time elevation, and the narrowest scopes your environment supports. These are starting points, not substitutes for your organization's access model or Microsoft's current documentation.

| Script | Module / connection | Suggested delegated Graph scope or role |
|---|---|---|
| `Get-M365LicenseReport.ps1` | Microsoft Graph | `Organization.Read.All` |
| `Get-M365InactiveUser.ps1` | Microsoft Graph | `User.Read.All`, `AuditLog.Read.All` |
| `Get-MfaRegistrationReport.ps1` | Microsoft Graph Reports | `AuditLog.Read.All`; Reports Reader or equivalent |
| `Get-EntraRoleAssignment.ps1` | Microsoft Graph | `RoleManagement.Read.Directory`, `Directory.Read.All` |
| `Get-GuestUserAudit.ps1` | Microsoft Graph | `User.Read.All`, `AuditLog.Read.All` |
| `Get-ConditionalAccessPolicyInventory.ps1` | Microsoft Graph | `Policy.Read.All` |
| `Test-M365DomainHealth.ps1` | Microsoft Graph | `Domain.Read.All` |
| `Get-ExchangeMailboxForwardingAudit.ps1` | Exchange Online | Recipient and accepted-domain read access |
| `Get-ExternalInboxRule.ps1` | Exchange Online | Recipient and inbox-rule read access |
| `Get-SharedMailboxPermission.ps1` | Exchange Online | Recipient permission read access |
| `Get-TeamsExternalAccessConfiguration.ps1` | Microsoft Teams | A role permitted to read federation configuration |
| `Export-M365SecuritySnapshot.ps1` | Graph and optional Exchange | Union of the reports selected |

## Verify the active Graph context

```powershell
Get-MgContext | Select-Object Account, TenantId, Scopes, AuthType
```

## End sessions when finished

```powershell
Disconnect-MgGraph
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MicrosoftTeams
```

## Application authentication

The scripts use the Microsoft Graph and Exchange cmdlets available in the current session, so certificate-based application authentication can be used where those cmdlets support it. Build and approve that model separately: application permissions are powerful and should not be inferred or consented by a downloaded script.
