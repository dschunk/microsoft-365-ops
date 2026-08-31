# SchunkOps Microsoft 365 — Help Desk Field Guide

This guide is for the first 5–15 minutes of a Microsoft 365 support ticket. The goal is to establish facts before changing licenses, resetting settings, removing MFA methods, editing forwarding, or escalating to an identity / messaging engineer.

The scripts in this repository are read-only. They require the operator to authenticate with Microsoft's supported modules before running them.

## First: connect only to what you need

For a basic Entra / Microsoft 365 user check:

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'
```

For friendly license names as well:

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All','Organization.Read.All'
```

For mailbox checks:

```powershell
Connect-ExchangeOnline
```

Use the least privilege your organization's support model permits. Do not paste tokens, exported tenant data, or real user data into public issues.

## “This user cannot sign in”

Start by establishing account state:

```powershell
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com
```

Check:

- `AccountEnabled`
- user type
- last successful sign-in
- last password change
- assigned license count
- whether the object is synchronized from on-premises
- last on-premises sync time

Then review MFA registration if your permissions allow it:

```powershell
./scripts/Get-MfaRegistrationReport.ps1 |
    Where-Object UserPrincipalName -eq 'alex@contoso.com'
```

Do not infer a Conditional Access failure from “MFA is registered.” Registration, authentication policy, risk, device state, location, and Conditional Access evaluation are different layers.

A senior escalation should include the user snapshot plus the exact sign-in error / correlation information available through your approved support process.

## “The user is missing an app / license”

```powershell
./scripts/Get-M365UserLicenseAssignment.ps1 -UserPrincipalName alex@contoso.com
```

This resolves assigned SKU GUIDs to tenant SKU part numbers and reports disabled service-plan IDs without changing the assignment.

For tenant-wide capacity:

```powershell
./scripts/Get-M365LicenseReport.ps1
```

Before changing a license, establish:

1. what is assigned now
2. whether the expected SKU exists in the tenant
3. whether capacity is available
4. whether service plans are selectively disabled
5. whether group-based licensing or another provisioning process owns the assignment

The read-only report intentionally does not try to “fix” licensing ownership.

## “Outlook / mailbox is weird”

```powershell
./scripts/Get-ExchangeMailboxSupportSnapshot.ps1 -Identity alex@contoso.com
```

The snapshot provides:

- recipient type
- primary SMTP address and aliases
- archive state
- mailbox-level forwarding
- retention policy
- litigation-hold state
- item count and size when statistics are available
- last logon time when the service exposes it

Then separate the symptom.

### Suspected forwarding

```powershell
./scripts/Get-ExchangeMailboxForwardingAudit.ps1 |
    Where-Object PrimarySmtpAddress -eq 'alex@contoso.com'

./scripts/Get-ExternalInboxRule.ps1 |
    Where-Object Mailbox -eq 'alex@contoso.com'
```

Mailbox forwarding and inbox-rule forwarding are different mechanisms. Check both before declaring the account clean.

### Shared mailbox access

```powershell
./scripts/Get-SharedMailboxPermission.ps1 |
    Where-Object PrimarySmtpAddress -eq 'finance@contoso.com'
```

Distinguish Full Access, Send As, and Send on Behalf. “I can open the mailbox” does not prove the user can send as it.

## “Teams cannot talk to an external company”

```powershell
./scripts/Get-TeamsExternalAccessConfiguration.ps1
```

This establishes the tenant-side external / federation configuration. It does not prove the remote tenant permits the same relationship, and it does not change policy.

Escalate with:

- affected internal identity
- external domain
- whether chat, meetings, calling, or guest access is the actual feature in question
- tenant external-access output
- whether the problem affects one user or the tenant

## “Is this guest account still legitimate?”

```powershell
./scripts/Get-GuestUserAudit.ps1
```

Use guest age, redemption state, sign-in activity, and ownership context as review signals—not as an automatic delete list.

## “Did somebody configure risky external mail flow?”

```powershell
./scripts/Get-ExchangeMailboxForwardingAudit.ps1 |
    Where-Object IsExternal

./scripts/Get-ExternalInboxRule.ps1 |
    Where-Object IsExternal
```

During an incident, preserve the output before remediation. If you need a wider tenant capture:

```powershell
./scripts/Export-M365SecuritySnapshot.ps1 -OutputDirectory C:\Evidence\M365
```

The snapshot writes structured reports, collection metadata, failures, and SHA-256 hashes. Review the output for sensitive identities and configuration before sharing it.

## Before escalating a Microsoft 365 ticket

A useful escalation answers:

1. **Which identity or object is affected?** UPN, mailbox, group, guest, domain, or tenant-wide setting.
2. **What exact operation fails?** Sign-in, license entitlement, Outlook access, Send As, forwarding, Teams federation, etc.
3. **When did it last work?** Include timezone.
4. **Is the problem isolated or widespread?** One user, one group, one service, one location, or the tenant.
5. **Is the user cloud-only or synchronized?** This changes where identity ownership lives.
6. **What evidence was collected?** Attach sanitized output from the relevant read-only scripts.
7. **What was not changed?** This prevents duplicated or destructive troubleshooting.

Example escalation:

```text
INC-2417
User alex@contoso.com cannot access an application expected from M365_E3.
Account is enabled and successfully signed in this morning.
Object is synchronized from on-premises; last directory sync is current.
M365_E3 is assigned, but the relevant service plan is disabled in the assignment.
No license, group membership, MFA, or Conditional Access changes performed.
Attached: user-support-snapshot.json and user-license-assignment.csv.
Escalation domain: license-assignment ownership / provisioning policy.
```

## The rule

**Collect first. Change second. Document always.**

The fastest support engineer is not the person who clicks the most buttons. It is the person who reduces uncertainty without destroying the evidence.
