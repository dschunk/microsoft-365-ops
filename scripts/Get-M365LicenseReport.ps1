# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Reports Microsoft 365 subscription utilization.
.DESCRIPTION
Returns one object per subscribed SKU with assigned, enabled, suspended, warning,
locked-out, and available unit counts. Requires an existing Microsoft Graph session.
.EXAMPLE
./Get-M365LicenseReport.ps1 | Sort-Object PercentConsumed -Descending
.NOTES
Suggested Graph permission: Organization.Read.All.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'Organization.Read.All'."
}

Get-MgSubscribedSku -All | ForEach-Object {
    $enabled = [int]$_.PrepaidUnits.Enabled
    $consumed = [int]$_.ConsumedUnits
    [pscustomobject]@{
        SkuPartNumber    = $_.SkuPartNumber
        SkuId            = $_.SkuId
        CapabilityStatus = $_.CapabilityStatus
        ConsumedUnits    = $consumed
        EnabledUnits     = $enabled
        AvailableUnits   = [math]::Max(0, $enabled - $consumed)
        SuspendedUnits   = [int]$_.PrepaidUnits.Suspended
        WarningUnits     = [int]$_.PrepaidUnits.Warning
        LockedOutUnits   = [int]$_.PrepaidUnits.LockedOut
        PercentConsumed  = if ($enabled -gt 0) { [math]::Round(($consumed / $enabled) * 100, 2) } else { 0 }
    }
}
