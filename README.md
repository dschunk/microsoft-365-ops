<p align="center">
  <img src="assets/schunkops-m365-banner.svg" alt="SchunkOps Microsoft 365" width="100%">
</p>

# SchunkOps Microsoft 365

> **Personal project notice:** This repository is independently maintained in a personal/open-source capacity and is not affiliated with, sponsored by, or endorsed by any current or former employer. It is intended to contain only generic, reusable Microsoft 365 administration and security-audit tooling. Do not contribute employer confidential or proprietary information, non-public tenant configuration, customer data, credentials, employer source code, or employer work product.

[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-2671BE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![CI](https://github.com/dschunk/microsoft-365-ops/actions/workflows/validate.yml/badge.svg)](https://github.com/dschunk/microsoft-365-ops/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-d4a72c.svg)](LICENSE)
[![Security: read only](https://img.shields.io/badge/default-read--only-2ea44f)](SECURITY.md)

**Twenty read-only PowerShell tools spanning first-contact Microsoft 365 support, Entra ID, Exchange Online, Teams, senior tenant engineering, security review, and incident evidence.**

Help desk gets fast user and mailbox facts. Microsoft 365 admins get clean audits. Senior engineers get sign-in, service-health, privilege, mail-flow, delegation, and evidence workflows without handing an unknown script permission to change the tenant.

> **Collect first. Change second. Document always.**

## Start here by problem

| Problem | Start with |
|---|---|
| **User cannot sign in / account looks wrong** | [`Get-M365UserSupportSnapshot.ps1`](scripts/Get-M365UserSupportSnapshot.ps1) |
| **Repeated sign-in failures / need error correlation** | [`Get-M365SignInFailureSummary.ps1`](scripts/Get-M365SignInFailureSummary.ps1) |
| **Is Microsoft 365 itself having an incident?** | [`Get-M365ServiceHealthIncident.ps1`](scripts/Get-M365ServiceHealthIncident.ps1) |
| **User is missing an app or license** | [`Get-M365UserLicenseAssignment.ps1`](scripts/Get-M365UserLicenseAssignment.ps1) |
| **Outlook / mailbox issue** | [`Get-ExchangeMailboxSupportSnapshot.ps1`](scripts/Get-ExchangeMailboxSupportSnapshot.ps1) |
| **Privileged-account hygiene** | [`Get-EntraPrivilegedUserReview.ps1`](scripts/Get-EntraPrivilegedUserReview.ps1) |
| **Mail-flow / transport-rule review** | [`Get-ExchangeTransportRuleAudit.ps1`](scripts/Get-ExchangeTransportRuleAudit.ps1) |
| **Who can access or impersonate mailboxes?** | [`Get-ExchangeMailboxDelegateExposure.ps1`](scripts/Get-ExchangeMailboxDelegateExposure.ps1) |
| **MFA registration review** | [`Get-MfaRegistrationReport.ps1`](scripts/Get-MfaRegistrationReport.ps1) |
| **External forwarding concern** | `Get-ExchangeMailboxForwardingAudit.ps1` + `Get-ExternalInboxRule.ps1` |
| **Teams external communication** | [`Get-TeamsExternalAccessConfiguration.ps1`](scripts/Get-TeamsExternalAccessConfiguration.ps1) |
| **Full tenant evidence capture** | [`Export-M365SecuritySnapshot.ps1`](scripts/Export-M365SecuritySnapshot.ps1) |

Field guides: **[Help Desk](docs/HELPDESK.md)** · **[Senior Admin](docs/SENIOR-ADMIN.md)**.

## Help desk: establish the facts first

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com
```

The snapshot returns account state, user type, last sign-in, last password change, license count, usage location, organizational metadata, and on-premises synchronization state in one object.

Friendly license assignments:

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All','Organization.Read.All'
./scripts/Get-M365UserLicenseAssignment.ps1 -UserPrincipalName alex@contoso.com
```

Exchange-side support context:

```powershell
Connect-ExchangeOnline
./scripts/Get-ExchangeMailboxSupportSnapshot.ps1 -Identity alex@contoso.com
```

**These support tools do not reset passwords, change MFA, assign licenses, edit forwarding, or modify mailbox state.** They reduce uncertainty before someone starts clicking buttons.

## Senior tenant engineering

### Repeated sign-in failures

```powershell
Connect-MgGraph -Scopes 'AuditLog.Read.All'
./scripts/Get-M365SignInFailureSummary.ps1 -Hours 24
```

For one user:

```powershell
./scripts/Get-M365SignInFailureSummary.ps1 `
    -UserPrincipalName alex@contoso.com `
    -Hours 48
```

Failures are grouped by user, application, client, error code, and failure reason while preserving first/last time, IPs, locations, Conditional Access status, risk, and correlation IDs.

### Is this Microsoft or our tenant?

```powershell
Connect-MgGraph -Scopes 'ServiceHealth.Read.All'
./scripts/Get-M365ServiceHealthIncident.ps1
```

Use service health before making broad tenant changes because several unrelated user reports can be one upstream incident.

### Privileged account review

```powershell
Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','Directory.Read.All','User.Read.All','AuditLog.Read.All'
./scripts/Get-EntraPrivilegedUserReview.ps1
```

This correlates active privileged role assignments with enabled/disabled state, last successful sign-in, MFA registration/capability, sync state, and review findings.

### Mail-flow rule review

```powershell
Connect-ExchangeOnline
./scripts/Get-ExchangeTransportRuleAudit.ps1 -OnlyReviewRecommended
```

The audit surfaces redirects, copy/BCC/add-recipient actions, external targets, deletion, rejection, quarantine, and stop-processing behavior without editing rules.

### Mailbox delegation exposure

```powershell
./scripts/Get-ExchangeMailboxDelegateExposure.ps1
```

Investigate a specific trustee:

```powershell
./scripts/Get-ExchangeMailboxDelegateExposure.ps1 -TrusteePattern '*alex*'
```

The report covers direct Full Access, Send As, and Send on Behalf assignments across user and shared mailboxes.

Read the complete **[Senior Admin Field Guide](docs/SENIOR-ADMIN.md)**.

## Tool catalog

| Tool | What it answers | Service |
|---|---|---|
| `Get-M365UserSupportSnapshot.ps1` | What is the current support state of this user account? | Microsoft Graph |
| `Get-M365UserLicenseAssignment.ps1` | Which friendly tenant SKUs are assigned to this user? | Microsoft Graph |
| `Get-ExchangeMailboxSupportSnapshot.ps1` | What is the current mailbox / forwarding / size context for this identity? | Exchange Online |
| `Get-M365SignInFailureSummary.ps1` | Which sign-in failures repeat by user/app/client/error, and where are they coming from? | Microsoft Graph Reports |
| `Get-M365ServiceHealthIncident.ps1` | Are current or recent Microsoft 365 service incidents relevant to the symptoms? | Microsoft Graph Service Health |
| `Get-EntraPrivilegedUserReview.ps1` | Which privileged users deserve review based on account, sign-in, and MFA state? | Microsoft Graph |
| `Get-ExchangeTransportRuleAudit.ps1` | Which mail-flow rules route, copy, reject, quarantine, or delete messages? | Exchange Online |
| `Get-ExchangeMailboxDelegateExposure.ps1` | Who has Full Access, Send As, or Send on Behalf across user/shared mailboxes? | Exchange Online |
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

Microsoft 365 support and engineering often begin with deceptively simple questions:

- Is the user actually enabled and signing in?
- Why is authentication failing repeatedly?
- Is there a Microsoft service incident or a tenant-local problem?
- Does the user really have the expected license?
- Which privileged accounts still deserve their assignments?
- Who can access or impersonate a mailbox?
- What mail-flow rules silently route, copy, reject, or delete mail?
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
Install-Module Microsoft.Graph.Devices.ServiceAnnouncement -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
```

Connect explicitly with only the scopes needed for the task. The scripts require an existing authenticated session. They deliberately do not open authentication prompts, accept passwords, or silently request extra permissions.

## Permission map

| Capability | Suggested delegated permission / role |
|---|---|
| User support snapshot | `User.Read.All`; `AuditLog.Read.All` for sign-in activity |
| User license resolution | `User.Read.All`, `Organization.Read.All` |
| Sign-in failure review | `AuditLog.Read.All` |
| Service health | `ServiceHealth.Read.All` |
| Privileged-user review | `RoleManagement.Read.Directory`, `Directory.Read.All`, `User.Read.All`, `AuditLog.Read.All` |
| Users and guests | `User.Read.All`, `AuditLog.Read.All` |
| Licenses and domains | `Organization.Read.All`, `Domain.Read.All` |
| MFA registration | `AuditLog.Read.All` plus Reports Reader or equivalent |
| Conditional Access | `Policy.Read.All` |
| Exchange support / audit | Exchange View-Only Recipients / View-Only Configuration where sufficient |
| Teams federation | Teams Communications Support Engineer or appropriate read role |

Permissions vary by tenant configuration and Microsoft may change API requirements. Review current Microsoft documentation and your organization's access policy before connecting.

Detailed guidance: [help desk field guide](docs/HELPDESK.md) · [senior admin field guide](docs/SENIOR-ADMIN.md) · [permission map](docs/PERMISSIONS.md) · [operator checklist](docs/OPERATOR-CHECKLIST.md) · [threat model](docs/THREAT-MODEL.md) · [roadmap](ROADMAP.md)

## Evidence patterns

### User authentication packet

```powershell
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com |
    ConvertTo-Json -Depth 6 |
    Set-Content ./alex-user.json

./scripts/Get-M365SignInFailureSummary.ps1 -UserPrincipalName alex@contoso.com -Hours 48 |
    ConvertTo-Json -Depth 8 |
    Set-Content ./alex-signin-failures.json
```

### Privileged access review

```powershell
./scripts/Get-EntraPrivilegedUserReview.ps1 |
    Where-Object ReviewPriority -ne 'Informational' |
    ConvertTo-Json -Depth 8 |
    Set-Content ./privileged-review.json
```

### Exchange exposure review

```powershell
./scripts/Get-ExchangeTransportRuleAudit.ps1 -OnlyReviewRecommended |
    ConvertTo-Json -Depth 8 |
    Set-Content ./transport-rules.json

./scripts/Get-ExchangeMailboxDelegateExposure.ps1 |
    Export-Csv ./mailbox-delegates.csv -NoTypeInformation
```

### Full security snapshot

```powershell
./scripts/Export-M365SecuritySnapshot.ps1 -OutputDirectory C:\Evidence\M365
```

The snapshot command writes JSON and CSV reports, a manifest, SHA-256 hashes, and a failure log when an optional data source is unavailable. It does not alter tenant state.

## Design promises

- **Read-only by default.** Inventory, correlation, and reporting are the product.
- **Support before remediation.** Establish account, sign-in, license, mailbox, policy, and service-health facts before changing state.
- **Object-first output.** Formatting belongs to the operator, not the function.
- **No credential handling.** Authentication remains with Microsoft's supported modules.
- **No silent privilege expansion.** Scripts use the operator's existing session and never request consent themselves.
- **Partial failure is visible.** Missing permissions become actionable errors, not empty “success.”
- **Sensitive output is labeled.** Reports can contain identities, IPs, configuration, permissions, and mail-flow data; handle them accordingly.
- **The next engineer matters.** Every script includes help, examples, and scope notes.

## Validation

GitHub Actions parses every script on Windows PowerShell and PowerShell 7, runs PSScriptAnalyzer, and enforces a Pester safety contract. The tests reject embedded authentication and credential-like parameters and enforce the read-only contract for support and senior tenant diagnostics. CI validates code quality; real-tenant behavior must still be tested in a non-production tenant with your policies and licenses.

## Contributing

Issues and pull requests are welcome. Please sanitize tenant names, domains, user identities, object IDs, exported data, IP addresses, and any employer-specific information before sharing diagnostics. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## Author and attribution

Built and maintained by [David Schunk](https://www.davidschunk.com/) in a personal/open-source capacity.

- [LinkedIn](https://www.linkedin.com/in/dschunk/)
- [Best Practices for Everyday IT newsletter](https://www.linkedin.com/newsletters/best-practices-for-everyday-it-7075059974573314048/)
- [More SchunkOps projects](https://github.com/dschunk)

If this toolkit saves you time, star the repository, link back to it in internal documentation, and keep the attribution header when adapting scripts. That makes the work discoverable while the MIT license keeps it useful.

## License

[MIT](LICENSE) © David Schunk
