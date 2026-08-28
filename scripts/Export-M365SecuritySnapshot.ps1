# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Creates a timestamped, integrity-hashed Microsoft 365 security snapshot.
.PARAMETER OutputDirectory
Parent directory for the generated snapshot. Defaults to the current directory.
.PARAMETER IncludeExchange
Includes Exchange forwarding and shared-mailbox permission reports when connected.
.EXAMPLE
./Export-M365SecuritySnapshot.ps1 -OutputDirectory C:\Evidence -IncludeExchange
.NOTES
Runs sibling audit scripts. Connect to Microsoft Graph and, optionally, Exchange Online first.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = (Get-Location).Path,
    [switch]$IncludeExchange
)

$ErrorActionPreference = 'Stop'
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$snapshotPath = Join-Path $OutputDirectory "M365-Security-Snapshot-$timestamp"
$null = New-Item -ItemType Directory -Path $snapshotPath -Force
$failures = [System.Collections.Generic.List[object]]::new()

$jobs = [ordered]@{
    'licenses'            = 'Get-M365LicenseReport.ps1'
    'inactive-users'      = 'Get-M365InactiveUser.ps1'
    'mfa-registration'    = 'Get-MfaRegistrationReport.ps1'
    'entra-roles'         = 'Get-EntraRoleAssignment.ps1'
    'guest-users'         = 'Get-GuestUserAudit.ps1'
    'conditional-access'  = 'Get-ConditionalAccessPolicyInventory.ps1'
    'domains'             = 'Test-M365DomainHealth.ps1'
}
if ($IncludeExchange) {
    $jobs['mailbox-forwarding'] = 'Get-ExchangeMailboxForwardingAudit.ps1'
    $jobs['external-inbox-rules'] = 'Get-ExternalInboxRule.ps1'
    $jobs['shared-mailbox-permissions'] = 'Get-SharedMailboxPermission.ps1'
}

foreach ($name in $jobs.Keys) {
    $scriptPath = Join-Path $PSScriptRoot $jobs[$name]
    try {
        $data = @(& $scriptPath -ErrorAction Stop)
        $data | Export-Csv (Join-Path $snapshotPath "$name.csv") -NoTypeInformation -Encoding utf8
        $data | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $snapshotPath "$name.json") -Encoding utf8
    } catch {
        $failures.Add([pscustomobject]@{
            Report  = $name
            Script  = $jobs[$name]
            Error   = $_.Exception.Message
        })
    }
}

if ($failures.Count) {
    $failures | Export-Csv (Join-Path $snapshotPath 'failures.csv') -NoTypeInformation -Encoding utf8
}

$manifest = [ordered]@{
    Toolkit          = 'SchunkOps Microsoft 365'
    CreatedAtUtc     = (Get-Date).ToUniversalTime().ToString('o')
    CreatedBy        = [Environment]::UserName
    ComputerName     = [Environment]::MachineName
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    GraphTenantId    = if (Get-Command Get-MgContext -ErrorAction SilentlyContinue) { (Get-MgContext).TenantId } else { $null }
    ReportsRequested = @($jobs.Keys)
    FailedReports    = @($failures.Report)
    Warning          = 'Contains sensitive tenant configuration and identity data. Protect according to organizational policy.'
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $snapshotPath 'manifest.json') -Encoding utf8

Get-ChildItem $snapshotPath -File | Where-Object Name -ne 'SHA256SUMS.txt' | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    '{0}  {1}' -f $hash.Hash.ToLowerInvariant(), $_.Name
} | Set-Content (Join-Path $snapshotPath 'SHA256SUMS.txt') -Encoding ascii

[pscustomobject]@{
    SnapshotPath     = $snapshotPath
    ReportsRequested = $jobs.Count
    ReportsSucceeded = $jobs.Count - $failures.Count
    ReportsFailed    = $failures.Count
    HashManifest     = Join-Path $snapshotPath 'SHA256SUMS.txt'
}
