# Classroom & Lab Guide

This repository can support courses in Microsoft 365 administration, Entra ID, Exchange Online, cloud identity, tenant security, PowerShell, and incident-response operations.

The scripts are intentionally **read-only-first**, which makes them useful for teaching how to establish facts before making tenant changes.

> Recommended environment: a dedicated lab or education tenant with synthetic users and test mailboxes. Do not use real student, employee, or customer data in public coursework.

## Learning objectives

Students should be able to:

- connect to Microsoft Graph and Exchange Online with the minimum required scopes;
- explain the difference between tenant state, user state, and upstream Microsoft service health;
- investigate sign-in, licensing, mailbox, privilege, forwarding, delegation, and guest-lifecycle questions;
- preserve evidence without silently changing tenant configuration;
- identify which permissions are required and why;
- distinguish “no finding” from “collector failed”;
- produce an escalation or review artifact another administrator can continue from.

## Lab 1 — User support snapshot

**Level:** introductory / intermediate

Connect:

```powershell
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'
```

Run:

```powershell
./scripts/Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com
```

Ask students to identify:

- account state;
- user type;
- synchronization state;
- sign-in evidence;
- license count;
- password-change context;
- which facts are sufficient for escalation and which are not.

## Lab 2 — License assignment

Use:

```powershell
./scripts/Get-M365UserLicenseAssignment.ps1 -UserPrincipalName alex@contoso.com
```

Students should explain the difference between:

- tenant SKU availability;
- assignment to the user;
- a service plan being disabled;
- an application problem that is unrelated to licensing.

## Lab 3 — Is this Microsoft or us?

Use:

```powershell
./scripts/Get-M365ServiceHealthIncident.ps1
```

Give students multiple mock user reports and ask whether they should first suspect:

1. an upstream service incident;
2. one identity;
3. one mailbox;
4. one network/client;
5. tenant configuration.

The exercise is about scope and correlation, not guessing.

## Lab 4 — Sign-in failure analysis

Use:

```powershell
./scripts/Get-M365SignInFailureSummary.ps1 -Hours 24
```

For one user:

```powershell
./scripts/Get-M365SignInFailureSummary.ps1 `
    -UserPrincipalName alex@contoso.com `
    -Hours 48
```

Students should group evidence by:

- application;
- client;
- error code;
- location/IP;
- Conditional Access state;
- risk context;
- correlation ID.

**Discussion:** Why is “reset the password” a poor first response when the failure evidence has not been classified?

## Lab 5 — Mailbox delegation and forwarding

Use:

```powershell
./scripts/Get-ExchangeMailboxDelegateExposure.ps1
./scripts/Get-ExchangeMailboxForwardingAudit.ps1
./scripts/Get-ExternalInboxRule.ps1
```

Students build a review table showing:

- who has Full Access;
- who can Send As / Send on Behalf;
- which mailboxes forward externally;
- which inbox rules redirect or forward mail.

**Learning goal:** understand that mailbox exposure can exist in several layers.

## Lab 6 — Privileged access review

Use:

```powershell
./scripts/Get-EntraPrivilegedUserReview.ps1
```

Students review privileged accounts using:

- assignment;
- enabled/disabled state;
- sign-in recency;
- MFA registration/capability;
- synchronization state;
- review findings.

**Discussion:** Which findings indicate risk, and which require business context before action?

## Lab 7 — Conditional Access inventory

Use:

```powershell
./scripts/Get-ConditionalAccessPolicyInventory.ps1
```

Have students create a diagram of:

- users/groups targeted;
- cloud apps targeted;
- conditions;
- controls;
- exclusions;
- enabled/report-only/off state.

**Assessment:** students explain why an inventory tool should not automatically “fix” policy design.

## Lab 8 — Guest lifecycle

Use:

```powershell
./scripts/Get-GuestUserAudit.ps1
```

Ask students to identify:

- stale guests;
- unaccepted invitations;
- inactive accounts;
- ownership/review questions.

Require a remediation proposal that includes business-owner validation before deletion.

## Lab 9 — Tenant evidence snapshot

Use:

```powershell
./scripts/Export-M365SecuritySnapshot.ps1
```

Students should explain:

- what was collected;
- when it was collected;
- which services were queried;
- what failed or was unavailable;
- how hashes/timestamps improve later review;
- which evidence should be treated as sensitive.

## Suggested capstone — Tenant operational review

Students perform a read-only review of a lab tenant and submit:

1. identity and sign-in findings;
2. privileged-access findings;
3. mailbox delegation / forwarding findings;
4. Conditional Access inventory;
5. guest-user findings;
6. service-health check;
7. evidence snapshot;
8. prioritized recommendations;
9. permissions used;
10. limitations and missing evidence.

The grade should reward **reasoning, evidence quality, permission discipline, and communication**, not the number of findings.

## Assessment rubric

| Area | Strong work |
|---|---|
| Scope | Student identifies exactly what question each tool answers |
| Permissions | Graph scopes / service roles are documented and justified |
| Evidence | Results are preserved and interpreted accurately |
| Safety | No tenant changes are made unless the lab explicitly calls for them |
| Security | No tokens, credentials, real user data, or tenant secrets are exposed |
| Reasoning | Facts, assumptions, and recommendations are separated |
| Handoff | Another admin could continue from the submitted work |
| Limitations | Missing permissions, API gaps, and collector failures are stated clearly |

## Instructor discussion prompts

- What is the difference between an identity issue and a Microsoft service incident?
- Why should service health be checked before broad tenant changes?
- Why are external forwarding and inbox rules different control surfaces?
- What makes delegated mailbox access risky or legitimate?
- Why is MFA registration evidence not the same as proof of secure behavior?
- How should guest accounts be reviewed without deleting legitimate collaboration?
- What should happen when a Graph request fails midway through an audit?
- Why is least-privilege API access part of operational quality, not only security?

## Safe classroom rules

Use:

- synthetic identities;
- test tenants;
- disposable mailboxes;
- non-production domains where possible.

Never publish:

- access tokens;
- refresh tokens;
- private tenant IDs when they should remain non-public;
- real employee/student/customer data;
- mailbox contents;
- private email addresses;
- incident evidence that has not been sanitized.

## Citation

This repository includes `CITATION.cff`. Use the repository citation metadata for academic or technical references.

## Related material

- [Help Desk Guide](HELPDESK.md)
- [Operator Checklist](OPERATOR-CHECKLIST.md)
- [Senior Admin Guide](SENIOR-ADMIN.md)
- [Permissions](PERMISSIONS.md)
- [Threat Model](THREAT-MODEL.md)
- [Profile-level Teaching Guide](https://github.com/dschunk/dschunk/blob/main/docs/CLASSROOM.md)
