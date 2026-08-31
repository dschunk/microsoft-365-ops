# Changelog

All notable changes to this project are documented here.

## 1.2.0 — 2026-08-31

- Expanded the toolkit from fifteen to twenty read-only Microsoft 365 operations tools.
- Added `Get-M365SignInFailureSummary.ps1` to group Entra sign-in failures by user, application, client, error code, and failure reason while preserving timestamps, IPs, Conditional Access state, risk, and correlation IDs.
- Added `Get-M365ServiceHealthIncident.ps1` for current and recent Microsoft 365 service-health incidents from Graph service announcements.
- Added `Get-EntraPrivilegedUserReview.ps1` to correlate privileged role assignments with account state, successful sign-in activity, and MFA registration.
- Added `Get-ExchangeTransportRuleAudit.ps1` for mail-flow rule actions, external routing/copy targets, deletion, rejection, quarantine, and stop-processing review.
- Added `Get-ExchangeMailboxDelegateExposure.ps1` for Full Access, Send As, and Send on Behalf exposure across user and shared mailboxes.
- Added a Senior Admin Field Guide for sign-in failure, service-health, privileged-account, mail-flow, delegation, and incident-evidence workflows.
- Expanded the permission map and Pester safety contract for the five senior tenant diagnostics.

## 1.1.0 — 2026-08-31

- Expanded the toolkit from twelve to fifteen read-only Microsoft 365 operations tools.
- Added `Get-M365UserSupportSnapshot.ps1` for first-contact Entra / Microsoft 365 user troubleshooting.
- Added `Get-M365UserLicenseAssignment.ps1` for friendly per-user SKU assignment evidence.
- Added `Get-ExchangeMailboxSupportSnapshot.ps1` for mailbox, alias, forwarding, archive, retention, hold, and statistics context.
- Added a Microsoft 365 Help Desk Field Guide for sign-in, licensing, mailbox, forwarding, shared mailbox, Teams, guest, and escalation workflows.
- Expanded the Pester safety contract to cover all fifteen scripts and explicitly guard the new support tools against state-changing commands.
- Reorganized the README around support problems while preserving least-privilege and operator-controlled authentication requirements.

## 1.0.0 — 2026-08-28

- Initial public release with twelve read-only Microsoft 365 operations tools.
- Added Microsoft Graph audits for licenses, inactive users, MFA registration, Entra roles, guests, Conditional Access, and domains.
- Added Exchange Online audits for forwarding, inbox rules, and shared mailbox permissions.
- Added Teams external-access configuration report.
- Added timestamped security snapshot with JSON, CSV, manifest, failure record, and SHA-256 hashes.
- Added Windows PowerShell and PowerShell 7 CI validation, security policy, contribution guidance, citation metadata, and attribution.
