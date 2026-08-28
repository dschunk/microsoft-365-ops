# Threat model

## Purpose

This toolkit reads Microsoft 365 configuration and identity data from an operator's existing authenticated sessions. Its main security objective is to answer operational questions without expanding access or changing tenant state.

## Trust boundaries

| Boundary | Trust decision | Control |
|---|---|---|
| Operator to Microsoft cloud | Identity and consent remain outside the scripts | Use supported Microsoft connection cmdlets and least-privilege scopes |
| Script to active session | The script can query only what the session permits | No embedded authentication, tokens, or automatic consent |
| Tenant to exported report | Results can contain sensitive identities and configuration | Explicit export commands, output warning, operator-controlled destination |
| Repository to operator | Public code may change over time | Review source, pin a commit, validate hashes, test outside production |
| Snapshot files to evidence consumer | Files could be altered after collection | SHA-256 manifest plus collection metadata |

## In scope

- accidental over-permissioning;
- hidden modification behavior;
- credentials copied into scripts or parameters;
- incomplete collection presented as success;
- sensitive report leakage;
- untraceable evidence changes;
- unsafe contributions containing real tenant data.

## Out of scope

- compromise of the operator workstation or PowerShell module supply chain;
- malicious Microsoft Graph, Exchange Online, or Teams service responses;
- authorization mistakes made before the script runs;
- organization-specific compliance determinations;
- remediation and tenant mutation.

## Mitigations

- Read-only tool intent is documented and tested in CI.
- Repository tests reject embedded `Connect-*` calls and credential-like parameters.
- Scripts use object output so the operator chooses presentation and storage.
- Snapshot collection records failed reports and never treats missing access as a clean finding.
- Snapshot artifacts include a SHA-256 checksum manifest.
- Security and contribution guidance prohibit real tenant exports.
- Microsoft permission requirements are mapped by command.

## Residual risk

Read access can still expose highly sensitive information. A malicious dependency, excessive active session, modified local copy, compromised workstation, or mishandled export can defeat repository-level controls. Review the exact commit and module provenance, isolate collection when warranted, and protect output as security evidence.
