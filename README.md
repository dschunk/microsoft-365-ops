<p align="center">
  <img src="assets/schunkops-m365-banner.svg" alt="SchunkOps Microsoft 365" width="100%">
</p>

# SchunkOps Microsoft 365

> **Personal project notice:** This repository is independently maintained in a personal/open-source capacity and is not affiliated with, sponsored by, or endorsed by any current or former employer. It is intended to contain only generic, reusable Microsoft 365 administration and security-audit tooling. Do not contribute employer confidential or proprietary information, non-public tenant configuration, customer data, credentials, employer source code, or employer work product.

[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-2671BE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![CI](https://github.com/dschunk/microsoft-365-ops/actions/workflows/validate.yml/badge.svg)](https://github.com/dschunk/microsoft-365-ops/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-d4a72c.svg)](LICENSE)
[![Security: read only](https://img.shields.io/badge/default-read--only-2ea44f)](SECURITY.md)

**Fifteen read-only PowerShell tools for Microsoft 365 support, Entra ID, Exchange Online, Teams, tenant review, and incident evidence.**

The goal is to make the same repository useful at multiple support tiers: help desk gets fast user/mailbox facts, Microsoft 365 admins get clean audits, and senior engineers get reproducible tenant evidence without handing an unknown script permission to change the environment.

## Start here by problem

| Problem | Start with |
|---|---|
| **User cannot sign in / account looks wrong** | [`Get-M365UserSupportSnapshot.ps1`](scripts/Get-M365UserSupportSnapshot.ps1) |
| **User is missing an app or license** | [`Get-M365UserLicenseAssignment.ps1`](scripts/Get-M365UserLicenseAssignment.ps1) |
| **Outlook / mailbox issue** | [`Get-ExchangeMailboxSupportSnapshot.ps1`](scripts/Get-ExchangeMailboxSupportSnapshot.ps1) |
| **MFA registration review** | [`Get-MfaRegistrationReport.ps1`](scripts/Get-MfaRegistrationReport.ps1) |
| **External forwarding concern** | `Get-ExchangeMailboxForwardingAudit.ps1` + `Get-ExternalInboxRule.ps1` |
| **Shared mailbox access** | [`Get-SharedMailboxPermission.ps1`](scripts/Get-SharedMailboxPermission.ps1) |
| **Teams external communication** | [`Get-TeamsExternalAccessConfiguration.ps1`](scripts/Get-TeamsExternalAccessConfiguration.ps1) |
| **Privileged access / Entra roles** | [`Get-EntraRoleAssignment.ps1`](scripts/Get-EntraRoleAssignment.ps1) |
| **Full tenant evidence capture** | [`Export-M365SecuritySnapshot.ps1`](scripts/Export-M365SecuritySnapshot.ps1) |

Help desk and escalation workflows: **[SchunkOps Microsoft 365 Help Desk Field Guide](docs/HELPDESK.md)**.

## Help desk: first-contact user snapshot

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com
```

The snapshot returns account state, user type, last sign-in, last password change, license count, usage location, organizational metadata, and on-premises synchronization state in one object.

Need friendly license assignments?

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All','Organization.Read.All'
./scripts/Get-M365UserLicenseAssignment.ps1 -UserPrincipalName alex@contoso.com
```

Need the Exchange side?

```powershell
Connect-ExchangeOnline
./scripts/Get-ExchangeMailboxSupportSnapshot.ps1 -Identity alex@contoso.com
```

The mailbox snapshot collects recipient type, SMTP aliases, archive status, retention / hold context, mailbox-level forwarding, and mailbox statistics when available.

**None of those three tools reset a password, change MFA, assign a license, edit forwarding, or modify the mailbox.** They exist to reduce uncertainty before someone starts clicking buttons.

## Tool catalog

| Tool | What it answers | Service |
|---|---|---|
| `Get-M365UserSupportSnapshot.ps1` | What is the current support state of this user account? | Microsoft Graph |
| `Get-M365UserLicenseAssignment.ps1` | Which friendly tenant SKUs are assigned to this user? | Microsoft Graph |
| `Get-ExchangeMailboxSupportSnapshot.ps1` | What is the current mailbox / forwarding / size context for this identity? | Exchange Online |
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

## Why this exists

Microsoft 365 tickets and reviews often begin with deceptively simple questions:

- Is the user actually enabled and signing in?
- Is this account cloud-only or synchronized from Active Directory?
- Does the user really have the expected license?
- Who has privileged access?
- Which accounts are inactive or missing MFA?
- Where can mail leave the organization automatically?
- Which guests, shared mailboxes, and external access paths need review?
- Can we preserve a repeatable tenant snapshot before an incident or change?

This project turns those questions into small, auditable tools rather than a single opaque mega-script.

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
| User support snapshot | `User.Read.All`; `AuditLog.Read.All` for sign-in activity |
| User license resolution | `User.Read.All`, `Organization.Read.All` |
| Users and guests | `User.Read.All`, `AuditLog.Read.All` |
| Licenses and domains | `Organization.Read.All`, `Domain.Read.All` |
| Entra roles | `RoleManagement.Read.Directory`, `Directory.Read.All` |
| MFA registration | `AuditLog.Read.All` plus Reports Reader or equivalent |
| Conditional Access | `Policy.Read.All` |
| Exchange support / audits | Exchange View-Only Recipients / View-Only Configuration where sufficient |
| Teams federation | Teams Communications Support Engineer or appropriate read role |

Permissions vary by tenant configuration and Microsoft may change API requirements. Review the current Microsoft documentation and your organization's access policy before connecting.

Detailed guidance: [help desk field guide](docs/HELPDESK.md) · [permission map](docs/PERMISSIONS.md) · [operator checklist](docs/OPERATOR-CHECKLIST.md) · [threat model](docs/THREAT-MODEL.md) · [roadmap](ROADMAP.md)

## Operational patterns

### Export a user support record

```powershell
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com |
    ConvertTo-Json -Depth 5 |
    Set-Content ./alex-support-snapshot.json
```

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
- **Support before remediation.** Establish account, license, mailbox, and policy facts before changing state.
- **Object-first output.** Formatting belongs to the operator, not the function.
- **No credential handling.** Authentication remains with Microsoft's supported modules.
- **Partial failure is visible.** Missing permissions become actionable errors, not empty “success.”
- **Sensitive output is labeled.** Reports can contain identities and configuration data; handle them accordingly.
- **The next engineer matters.** Every script includes help, examples, and scope notes.

## Validation

GitHub Actions parses every script on Windows PowerShell and PowerShell 7, runs PSScriptAnalyzer, and enforces a Pester safety contract. The tests reject embedded authentication and credential-like parameters and enforce the read-only contract for help desk snapshot tools. CI validates code quality; real-tenant behavior must still be tested in a non-production tenant with your policies and licenses.

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
