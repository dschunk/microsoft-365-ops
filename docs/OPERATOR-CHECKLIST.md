# Microsoft 365 review checklist

## Before collection

- Define the business question and report owner.
- Confirm tenant, account, elevation window, scopes, and administrative roles.
- Create an approved encrypted output location.
- Record PowerShell and module versions.
- Review the source at the commit you intend to run.
- Test the exact command in a non-production tenant when possible.

## During collection

- Verify `Get-MgContext` before querying Graph.
- Preserve errors; an empty report is not proof that no findings exist.
- Avoid transcript logging unless the destination is approved for tenant data.
- Do not email raw exports or paste them into public tickets.

## After collection

- Verify `SHA256SUMS.txt` when using the snapshot tool.
- Record the commit SHA, timestamp, tenant ID, operator, and failed reports.
- Triage privileged roles, MFA gaps, external forwarding, stale guests, and disabled Conditional Access first.
- Assign each finding an owner, decision, and review date.
- Remove exported data according to the approved retention schedule.
- Disconnect cloud sessions and remove unnecessary elevation.
