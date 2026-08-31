# SchunkOps Microsoft 365 Senior Admin Field Guide

This guide is for tenant problems that have already moved beyond first-contact support: repeated sign-in failures, service-health correlation, privileged-account hygiene, transport-rule review, mailbox delegation exposure, and incident evidence.

The operating model is the same as the Windows toolkit:

> **Collect first. Change second. Document always.**

The tools in this guide are read-only. They do not reset passwords, revoke sessions, change MFA, assign licenses, edit Conditional Access, modify transport rules, remove delegates, or change mailbox state.

## User keeps failing to sign in

Connect with the operator-approved permissions first:

```powershell
Connect-MgGraph -Scopes 'AuditLog.Read.All'
```

Then group recent failed sign-ins:

```powershell
./scripts/Get-M365SignInFailureSummary.ps1 -Hours 24
```

For one user:

```powershell
./scripts/Get-M365SignInFailureSummary.ps1 `
    -UserPrincipalName alex@contoso.com `
    -Hours 48
```

The output groups repeated failures by user, application, client type, error code, and failure reason, then preserves first/last timestamps, IP addresses, locations, Conditional Access status, risk level, and correlation IDs.

Useful escalation packet:

```powershell
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com
./scripts/Get-M365UserLicenseAssignment.ps1 -UserPrincipalName alex@contoso.com
./scripts/Get-M365SignInFailureSummary.ps1 -UserPrincipalName alex@contoso.com -Hours 48
```

That separates “the account is wrong” from “authentication is failing somewhere else.”

## Is this Microsoft or us?

When multiple users suddenly report the same problem, check tenant service health before making broad configuration changes:

```powershell
Connect-MgGraph -Scopes 'ServiceHealth.Read.All'
./scripts/Get-M365ServiceHealthIncident.ps1
```

Filter by service:

```powershell
./scripts/Get-M365ServiceHealthIncident.ps1 -Service '*Exchange*'
```

The report preserves service, feature, status, classification, start/end time, last modification time, and impact description.

## Privileged-account review

A role assignment by itself is not enough context. Correlate privileged roles with account state, sign-in activity, and MFA registration:

```powershell
Connect-MgGraph -Scopes \
    'RoleManagement.Read.Directory',\
    'Directory.Read.All',\
    'User.Read.All',\
    'AuditLog.Read.All'

./scripts/Get-EntraPrivilegedUserReview.ps1
```

The report highlights review findings such as:

- privileged role assigned to a disabled account
- privileged account not reported MFA capable
- no MFA registration record
- no successful sign-in recorded
- privileged role still present after a long period of inactivity

Filter to administrator roles:

```powershell
./scripts/Get-EntraPrivilegedUserReview.ps1 -RoleName '*Administrator*' |
    Where-Object ReviewPriority -ne 'Informational'
```

Treat the output as a review queue, not an automatic remediation list.

## Mail-flow rule review

Exchange transport rules can legitimately route, copy, reject, quarantine, or delete messages. They can also become invisible operational dependencies if nobody remembers why they exist.

```powershell
Connect-ExchangeOnline
./scripts/Get-ExchangeTransportRuleAudit.ps1
```

Focus on rules with actions that deserve human review:

```powershell
./scripts/Get-ExchangeTransportRuleAudit.ps1 -OnlyReviewRecommended
```

The audit highlights redirects, BCC/copy/add-recipient actions, external targets, deletion, rejection, quarantine, and stop-processing behavior.

## Who can access or impersonate mailboxes?

Shared mailbox review is useful, but senior tenant review often needs user mailboxes too:

```powershell
./scripts/Get-ExchangeMailboxDelegateExposure.ps1
```

Investigate one delegate across the tenant:

```powershell
./scripts/Get-ExchangeMailboxDelegateExposure.ps1 -TrusteePattern '*alex*'
```

The report inventories direct Full Access, Send As, and Send on Behalf assignments across user and shared mailboxes. Inherited entries are excluded unless explicitly requested.

## Tenant incident evidence

Preserve a broader security snapshot:

```powershell
./scripts/Export-M365SecuritySnapshot.ps1 -OutputDirectory C:\Evidence\M365
```

Add targeted evidence beside it:

```powershell
./scripts/Get-M365SignInFailureSummary.ps1 -Hours 48 |
    Export-Csv C:\Evidence\M365\sign-in-failures.csv -NoTypeInformation

./scripts/Get-EntraPrivilegedUserReview.ps1 |
    ConvertTo-Json -Depth 8 |
    Set-Content C:\Evidence\M365\privileged-user-review.json

./scripts/Get-ExchangeTransportRuleAudit.ps1 |
    ConvertTo-Json -Depth 8 |
    Set-Content C:\Evidence\M365\transport-rules.json
```

Then document:

1. what users reported,
2. when symptoms began,
3. whether Microsoft service health reported an incident,
4. which sign-in error codes and Conditional Access results were observed,
5. which privileged, mail-flow, or delegation paths were relevant,
6. what was **not** changed during evidence collection,
7. what changed during remediation.

The goal is a tenant handoff another engineer can continue without reconstructing the investigation from browser history.
