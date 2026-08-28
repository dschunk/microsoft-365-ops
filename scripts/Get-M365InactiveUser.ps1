# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Finds enabled Microsoft 365 member accounts with stale sign-in activity.
.PARAMETER InactiveDays
Number of days since the last successful sign-in. Defaults to 90.
.PARAMETER IncludeNeverSignedIn
Includes enabled accounts for which Graph reports no sign-in activity.
.EXAMPLE
./Get-M365InactiveUser.ps1 -InactiveDays 60 -IncludeNeverSignedIn
.NOTES
Suggested Graph permissions: User.Read.All and AuditLog.Read.All.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 3650)]
    [int]$InactiveDays = 90,
    [switch]$IncludeNeverSignedIn
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'."
}

$cutoff = (Get-Date).ToUniversalTime().AddDays(-$InactiveDays)
$properties = @('id','displayName','userPrincipalName','accountEnabled','userType','createdDateTime','signInActivity','assignedLicenses')

Get-MgUser -All -Property $properties | Where-Object {
    if (-not $_.AccountEnabled -or $_.UserType -ne 'Member') { return $false }
    $lastSignIn = $_.SignInActivity.LastSuccessfulSignInDateTime
    ($lastSignIn -and ([datetime]$lastSignIn).ToUniversalTime() -lt $cutoff) -or ($IncludeNeverSignedIn -and -not $lastSignIn)
} | ForEach-Object {
    $lastSignIn = $_.SignInActivity.LastSuccessfulSignInDateTime
    [pscustomobject]@{
        DisplayName       = $_.DisplayName
        UserPrincipalName = $_.UserPrincipalName
        ObjectId          = $_.Id
        LastSuccessfulSignIn = $lastSignIn
        DaysSinceSignIn   = if ($lastSignIn) { [math]::Floor(((Get-Date).ToUniversalTime() - ([datetime]$lastSignIn).ToUniversalTime()).TotalDays) } else { $null }
        NeverSignedIn     = -not [bool]$lastSignIn
        CreatedDateTime   = $_.CreatedDateTime
        LicenseCount      = @($_.AssignedLicenses).Count
        ReviewReason      = if ($lastSignIn) { "No successful sign-in in $InactiveDays days" } else { 'No successful sign-in recorded' }
    }
}
