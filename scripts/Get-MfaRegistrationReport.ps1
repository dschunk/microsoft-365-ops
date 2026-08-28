# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Reports Microsoft Entra authentication-method registration status.
.PARAMETER OnlyAtRisk
Returns users who are not MFA registered or not MFA capable.
.EXAMPLE
./Get-MfaRegistrationReport.ps1 -OnlyAtRisk | Export-Csv ./mfa-gaps.csv -NoTypeInformation
.NOTES
Suggested Graph permission: AuditLog.Read.All. A supported Entra license and Reports Reader or equivalent role may be required.
#>
[CmdletBinding()]
param([switch]$OnlyAtRisk)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'AuditLog.Read.All'."
}

$results = Get-MgReportAuthenticationMethodUserRegistrationDetail -All
if ($OnlyAtRisk) {
    $results = $results | Where-Object { -not $_.IsMfaRegistered -or -not $_.IsMfaCapable }
}

$results | ForEach-Object {
    [pscustomobject]@{
        UserPrincipalName      = $_.UserPrincipalName
        UserDisplayName        = $_.UserDisplayName
        IsAdmin                = $_.IsAdmin
        IsMfaRegistered        = $_.IsMfaRegistered
        IsMfaCapable           = $_.IsMfaCapable
        IsPasswordlessCapable  = $_.IsPasswordlessCapable
        IsSsprRegistered       = $_.IsSsprRegistered
        IsSsprCapable          = $_.IsSsprCapable
        MethodsRegistered      = (@($_.MethodsRegistered) -join ';')
        DefaultMfaMethod       = $_.DefaultMfaMethod
        LastUpdatedDateTime    = $_.LastUpdatedDateTime
        ReviewPriority         = if ($_.IsAdmin -and -not $_.IsMfaCapable) { 'Critical' } elseif (-not $_.IsMfaCapable) { 'High' } elseif (-not $_.IsMfaRegistered) { 'Medium' } else { 'Informational' }
    }
}
