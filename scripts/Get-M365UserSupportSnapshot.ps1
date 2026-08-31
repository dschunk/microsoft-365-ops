# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Collects a concise Microsoft 365 / Entra user support snapshot for one account.
.PARAMETER UserPrincipalName
User principal name of the account to inspect.
.EXAMPLE
./Get-M365UserSupportSnapshot.ps1 -UserPrincipalName alex@contoso.com
.NOTES
Suggested Graph permissions: User.Read.All and AuditLog.Read.All for sign-in activity.
Requires an existing Microsoft Graph session. The script does not authenticate or modify the user.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All'."
}

$properties = @(
    'id',
    'displayName',
    'userPrincipalName',
    'mail',
    'accountEnabled',
    'userType',
    'createdDateTime',
    'lastPasswordChangeDateTime',
    'signInActivity',
    'assignedLicenses',
    'usageLocation',
    'companyName',
    'department',
    'jobTitle',
    'officeLocation',
    'onPremisesSyncEnabled',
    'onPremisesLastSyncDateTime',
    'onPremisesImmutableId'
)

$user = Get-MgUser -UserId $UserPrincipalName -Property $properties -ErrorAction Stop
$lastSuccessfulSignIn = $user.SignInActivity.LastSuccessfulSignInDateTime
$lastInteractiveSignIn = $user.SignInActivity.LastSignInDateTime
$now = (Get-Date).ToUniversalTime()

[pscustomobject]@{
    DisplayName                 = $user.DisplayName
    UserPrincipalName           = $user.UserPrincipalName
    Mail                        = $user.Mail
    ObjectId                    = $user.Id
    AccountEnabled              = [bool]$user.AccountEnabled
    UserType                    = $user.UserType
    CreatedDateTime             = $user.CreatedDateTime
    LastPasswordChangeDateTime  = $user.LastPasswordChangeDateTime
    LastSuccessfulSignIn        = $lastSuccessfulSignIn
    DaysSinceSuccessfulSignIn   = if ($lastSuccessfulSignIn) { [math]::Floor(($now - ([datetime]$lastSuccessfulSignIn).ToUniversalTime()).TotalDays) } else { $null }
    LastInteractiveSignIn       = $lastInteractiveSignIn
    AssignedLicenseCount        = @($user.AssignedLicenses).Count
    UsageLocation               = $user.UsageLocation
    CompanyName                 = $user.CompanyName
    Department                  = $user.Department
    JobTitle                    = $user.JobTitle
    OfficeLocation              = $user.OfficeLocation
    OnPremisesSyncEnabled       = [bool]$user.OnPremisesSyncEnabled
    OnPremisesLastSyncDateTime  = $user.OnPremisesLastSyncDateTime
    HasOnPremisesImmutableId    = [bool]$user.OnPremisesImmutableId
    CollectedAtUtc              = $now
}
