# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Audits Microsoft Entra guest accounts for age and sign-in inactivity.
.PARAMETER StaleDays
Age or inactivity threshold used to flag a guest for review.
.EXAMPLE
./Get-GuestUserAudit.ps1 -StaleDays 180 | Where-Object ReviewRecommended
.NOTES
Suggested Graph permissions: User.Read.All and AuditLog.Read.All.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 3650)]
    [int]$StaleDays = 180
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'."
}

$now = (Get-Date).ToUniversalTime()
$cutoff = $now.AddDays(-$StaleDays)
$properties = @('id','displayName','userPrincipalName','mail','accountEnabled','createdDateTime','externalUserState','externalUserStateChangeDateTime','signInActivity','sponsors')

Get-MgUser -All -Filter "userType eq 'Guest'" -Property $properties | ForEach-Object {
    $lastSignIn = $_.SignInActivity.LastSuccessfulSignInDateTime
    $created = [datetime]$_.CreatedDateTime
    $stale = ($lastSignIn -and ([datetime]$lastSignIn).ToUniversalTime() -lt $cutoff) -or (-not $lastSignIn -and $created.ToUniversalTime() -lt $cutoff)
    $pending = $_.ExternalUserState -eq 'PendingAcceptance'
    [pscustomobject]@{
        DisplayName             = $_.DisplayName
        UserPrincipalName       = $_.UserPrincipalName
        Mail                    = $_.Mail
        ObjectId                = $_.Id
        AccountEnabled          = $_.AccountEnabled
        InvitationState         = $_.ExternalUserState
        InvitationStateChanged  = $_.ExternalUserStateChangeDateTime
        CreatedDateTime         = $_.CreatedDateTime
        LastSuccessfulSignIn    = $lastSignIn
        DaysSinceActivity       = if ($lastSignIn) { [math]::Floor(($now - ([datetime]$lastSignIn).ToUniversalTime()).TotalDays) } else { $null }
        SponsorCount            = @($_.Sponsors).Count
        ReviewRecommended       = [bool]($stale -or $pending -or -not $_.AccountEnabled)
        ReviewReason            = (@(
            if ($stale) { "Inactive for at least $StaleDays days" }
            if ($pending) { 'Invitation still pending' }
            if (-not $_.AccountEnabled) { 'Account disabled' }
        ) -join '; ')
    }
}
