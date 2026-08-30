<p align="center">
  <img src="assets/schunkops-m365-banner.svg" alt="SchunkOps Microsoft 365" width="100%">
</p>

# SchunkOps Microsoft 365

> **Personal project notice:** This repository is independently maintained in a personal/open-source capacity and is not affiliated with, sponsored by, or endorsed by any current or former employer. It is intended to contain only generic, reusable Microsoft 365 administration and security-audit tooling. Do not contribute employer confidential or proprietary information, non-public tenant configuration, customer data, credentials, employer source code, or employer work product.

[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-2671BE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![CI](https://github.com/dschunk/microsoft-365-ops/actions/workflows/validate.yml/badge.svg)](https://github.com/dschunk/microsoft-365-ops/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-d4a72c.svg)](LICENSE)
[![Security: read only](https://img.shields.io/badge/default-read--only-2ea44f)](SECURITY.md)

Practical, inspectable PowerShell audits for Microsoft 365, Microsoft Entra ID, Exchange Online, and Teams. The toolkit is designed for administrators who need **useful answers without giving an unknown script permission to change their tenant**.

Every command emits PowerShell objects, supports normal pipelines and exports, and documents the permissions it needs. No credentials are accepted. No secrets are stored. No tenant data is included in this repository.

## Why this exists

Tenant reviews often begin with five deceptively simple questions:

- Who has privileged access?
- Which accounts are inactive, unlicensed, or missing MFA?
- Where can mail leave the organization automatically?
- Which guests, shared mailboxes, and external access paths need review?
- Can we capture a repeatable security snapshot before an incident or change?

This project turns those questions into small, auditable tools rather than a single opaque mega-script.

## Tool catalog

| Tool | What it answers | Service |
|---|---|---|
| `Get-M365LicenseReport.ps1` | Which licenses are assigned, consumed, and available? | Microsoft Graph |
| `Get-M365InactiveUser.ps1` | Which enabled member accounts have gone quiet? | Microsoft Graph |
| `Get-EntraRoleAssignment.ps1` | Who holds privileged Entra roles, directly or through groups? | Microsoft Graph |
| `Get-MfaRegistrationReport.ps1` | Who is registered and capable for MFA? | Microsoft Graph Reports |
| `Get-GuestUserAudit.ps1` | Which guests are stale, unaccepted, or ownerless? | Microsoft Graph |
| `Get-ConditionalAccessPolicyInventory.ps1` | What do Conditional Access policies target and enforce? | Microsoft Graph |
| `Get-ExchangeMailboxForwardingAudit.ps1` | Which mailboxes forward mail elsewhere? | Exchange Online |
| `Get-ExternalInboxRule.ps1` | Which inbox rules redirect or forward messages? | Exchange Online |
| `Get-SharedMailboxPermission.ps1` | Who can access or send as shared mailboxes? | Exchange Online |
| `Get-TeamsExternalAccessConfiguration.ps1` | How is Teams federation and external access configured? | Microsoft Teams |
| `Test-M365DomainHealth.ps1` | Are tenant domains verified and healthy? | Microsoft Graph |
| `Export-M365SecuritySnapshot.ps1` | Can I preserve a timestamped, hashed audit bundle? | Graph + Exchange |

## Safe quick start

Install only the modules needed for the audit you plan to run:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Scope CurrentUser
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
Install-Module Microsoft.Graph.Reports -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
```

Connect explicitly with the least-privilege scopes for the tool you need:

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'
./scripts/Get-M365InactiveUser.ps1 -InactiveDays 90 |
    Export-Csv ./inactive-users.csv -NoTypeInformation
```

Exchange example:

```powershell
Connect-ExchangeOnline
./scripts/Get-ExchangeMailboxForwardingAudit.ps1 |
    Where-Object IsExternal |
    Format-Table
```

> The scripts require an existing authenticated session. They deliberately do not open authentication prompts, accept passwords, or silently request extra permissions.

## Permission map

| Capability | Suggested delegated permission / role |
|---|---|
| Users and guests | `User.Read.All`, `AuditLog.Read.All` |
| Licenses and domains | `Organization.Read.All`, `Domain.Read.All` |
| Entra roles | `RoleManagement.Read.Directory`, `Directory.Read.All` |
| MFA registration | `AuditLog.Read.All` plus Reports Reader or equivalent |
| Conditional Access | `Policy.Read.All` |
| Exchange audits | Exchange View-Only Recipients / View-Only Configuration where sufficient |
| Teams federation | Teams Communications Support Engineer or appropriate read role |

Permissions vary by tenant configuration and Microsoft may change API requirements. Review the current Microsoft documentation and your organization's access policy before connecting.

Detailed guidance: [permission map](docs/PERMISSIONS.md) · [operator checklist](docs/OPERATOR-CHECKLIST.md) · [threat model](docs/THREAT-MODEL.md) · [roadmap](ROADMAP.md)

## Operational patterns

### Export clean CSV

```powershell
./scripts/Get-EntraRoleAssignment.ps1 |
    Sort-Object RoleName, PrincipalDisplayName |
    Export-Csv ./entra-role-assignments.csv -NoTypeInformation
```

### Find external forwarding

```powershell
./scripts/Get-ExchangeMailboxForwardingAudit.ps1 |
    Where-Object IsExternal |
    Select-Object DisplayName, PrimarySmtpAddress, ForwardingTarget
```

### Create an evidence bundle

```powershell
./scripts/Export-M365SecuritySnapshot.ps1 -OutputDirectory C:\Evidence\M365
```

The snapshot command writes JSON and CSV reports, a manifest, SHA-256 hashes, and a failure log when an optional data source is unavailable. It does not alter tenant state.

## Design promises

- **Read-only by default.** Inventory and reporting are the product.
- **Object-first output.** Formatting belongs to the operator, not the function.
- **No credential handling.** Authentication remains with Microsoft's supported modules.
- **Partial failure is visible.** Missing permissions become actionable errors, not empty “success.”
- **Sensitive output is labeled.** Reports can contain identities and configuration data; handle them accordingly.
- **The next engineer matters.** Every script includes help, examples, and scope notes.

## Validation

GitHub Actions parses every script on Windows PowerShell and PowerShell 7, runs PSScriptAnalyzer, and enforces a Pester safety contract. The tests reject embedded authentication and credential-like parameters. CI validates code quality; real-tenant behavior must still be tested in a non-production tenant with your policies and licenses.

## Contributing

Issues and pull requests are welcome. Please sanitize tenant names, domains, user identities, object IDs, exported data, and any employer-specific information before sharing diagnostics. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## Author and attribution

Built and maintained by [David Schunk](https://www.davidschunk.com/) in a personal/open-source capacity.

- [LinkedIn](https://www.linkedin.com/in/dschunk/)
- [Best Practices for Everyday IT newsletter](https://www.linkedin.com/newsletters/best-practices-for-everyday-it-7075059974573314048/)
- [More SchunkOps projects](https://github.com/dschunk)

If this toolkit saves you time, star the repository, link back to it in internal documentation, and keep the attribution header when adapting scripts. That makes the work discoverable while the MIT license keeps it useful.

## License

[MIT](LICENSE) © David Schunk

