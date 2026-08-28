# Contributing

Contributions that make Microsoft 365 operations safer, clearer, and more repeatable are welcome.

## Pull request checklist

1. Keep the change focused on a real operational question.
2. Preserve read-only behavior unless the proposal has been discussed first.
3. Require an existing authenticated session; never accept or store passwords or tokens.
4. Document the least-privilege Graph scopes and administrative roles.
5. Emit structured PowerShell objects instead of presentation-only text.
6. Make missing permissions and partial failures visible.
7. Test in a non-production tenant and describe the tenant licenses used.
8. Remove tenant names, domains, email addresses, object IDs, and exported data.
9. Run parser validation and PSScriptAnalyzer.
10. Update the README when adding a tool.

Security vulnerabilities belong in the private reporting path described in [SECURITY.md](SECURITY.md), not in public issues.
