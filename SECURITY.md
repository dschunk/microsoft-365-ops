# Security policy

## Read-only scope

The published scripts are intended to inventory and report. They do not intentionally modify tenant state. Review every script, verify its requested scopes, and test it in a non-production tenant before operational use.

## Protect the output

Reports may contain names, email addresses, object IDs, group membership, role assignments, authentication posture, forwarding targets, domains, and security-policy configuration. Treat generated output as sensitive operational data:

- store it only in approved locations;
- encrypt it in transit and at rest;
- restrict access and retention;
- sanitize it before opening an issue or pull request;
- never commit real tenant exports to Git.

## Reporting a vulnerability

Do not publish exploitable details or tenant data in a public issue. Contact the maintainer through the private contact options at [davidschunk.com](https://www.davidschunk.com/) and include the affected file, impact, sanitized reproduction steps, and a suggested mitigation if available.

## Microsoft cloud responsibility

Permissions, APIs, licenses, and returned fields may vary. Operators remain responsible for tenant access controls, change approval, data handling, compliance, and validating current Microsoft documentation.
