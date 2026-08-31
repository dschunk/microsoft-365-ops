# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Correlates privileged Entra role assignments with user, sign-in, and MFA registration state.
.PARAMETER RoleName
Optional wildcard filter for privileged role display names.
.PARAMETER StaleSignInDays
Days since the last successful sign-in that should trigger a stale-role review finding. Defaults to 90.
.EXAMPLE
./Get-EntraPrivilegedUserReview.ps1
.EXAMPLE
./Get-EntraPrivilegedUserReview.ps1 -RoleName '*Administrator*' -StaleSignInDays 60
.NOTES
Suggested Graph permissions: RoleManagement.Read.Directory, Directory.Read.All, User.Read.All, AuditLog.Read.All.
#>
[CmdletBinding()]
param(
    [string]$RoleName = '*',
    [ValidateRange(1, 3650)]
    [int]$StaleSignInDays = 90
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Connect with RoleManagement.Read.Directory, Directory.Read.All, User.Read.All, and AuditLog.Read.All."
}

$required = @(
    'Get-MgRoleManagementDirectoryRoleDefinition',
    'Get-MgRoleManagementDirectoryRoleAssignment',
    'Get-MgUser',
    'Get-MgReportAuthenticationMethodUserRegistrationDetail'
)
foreach ($command in $required) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required Microsoft Graph command is unavailable: $command"
    }
}

$definitions = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object {
    $definitions[[string]$_.Id] = $_
}

$userAssignments = @{}
Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty Principal | ForEach-Object {
    $definition = $definitions[[string]$_.RoleDefinitionId]
    if (-not $definition -or -not $definition.IsPrivileged -or $definition.DisplayName -notlike $RoleName) { return }

    $principalType = [string]$_.Principal.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
    if ($principalType -ne 'user') { return }

    $principalId = [string]$_.PrincipalId
    if (-not $userAssignments.ContainsKey($principalId)) {
        $userAssignments[$principalId] = @()
    }
    $userAssignments[$principalId] += [pscustomobject]@{
        RoleName = $definition.DisplayName
        RoleTemplateId = $definition.TemplateId
        AssignmentId = $_.Id
        DirectoryScopeId = $_.DirectoryScopeId
        AppScopeId = $_.AppScopeId
    }
}

$mfaByUserId = @{}
Get-MgReportAuthenticationMethodUserRegistrationDetail -All | ForEach-Object {
    if ($_.Id) { $mfaByUserId[[string]$_.Id] = $_ }
}

$staleCutoff = (Get-Date).ToUniversalTime().AddDays(-$StaleSignInDays)
$results = foreach ($userId in $userAssignments.Keys) {
    $user = Get-MgUser -UserId $userId -Property @(
        'id','displayName','userPrincipalName','accountEnabled','userType','createdDateTime',
        'signInActivity','assignedLicenses','onPremisesSyncEnabled'
    )
    $registration = $mfaByUserId[$userId]
    $lastSignIn = $user.SignInActivity.LastSuccessfulSignInDateTime
    $lastSignInUtc = if ($lastSignIn) { ([datetime]$lastSignIn).ToUniversalTime() } else { $null }
    $roles = @($userAssignments[$userId] | Sort-Object RoleName)

    $findings = @()
    if (-not $user.AccountEnabled) { $findings += 'Privileged role remains assigned to a disabled account' }
    if (-not $registration) { $findings += 'MFA registration report has no record for this privileged user' }
    elseif (-not $registration.IsMfaCapable) { $findings += 'Privileged user is not reported MFA capable' }
    elseif (-not $registration.IsMfaRegistered) { $findings += 'Privileged user is not reported MFA registered' }
    if (-not $lastSignInUtc) { $findings += 'No successful sign-in is recorded' }
    elseif ($lastSignInUtc -lt $staleCutoff) { $findings += "No successful sign-in in $StaleSignInDays days" }

    $priority = if ($findings -match 'not reported MFA capable') {
        'Critical'
    }
    elseif ($findings.Count -gt 0) {
        'High'
    }
    else {
        'Informational'
    }

    [pscustomobject]@{
        UserPrincipalName = $user.UserPrincipalName
        DisplayName = $user.DisplayName
        UserId = $user.Id
        AccountEnabled = $user.AccountEnabled
        UserType = $user.UserType
        OnPremisesSyncEnabled = $user.OnPremisesSyncEnabled
        LicenseCount = @($user.AssignedLicenses).Count
        CreatedDateTime = $user.CreatedDateTime
        LastSuccessfulSignInUtc = $lastSignInUtc
        DaysSinceSuccessfulSignIn = if ($lastSignInUtc) { [math]::Floor(((Get-Date).ToUniversalTime() - $lastSignInUtc).TotalDays) } else { $null }
        IsMfaRegistered = if ($registration) { $registration.IsMfaRegistered } else { $null }
        IsMfaCapable = if ($registration) { $registration.IsMfaCapable } else { $null }
        IsPasswordlessCapable = if ($registration) { $registration.IsPasswordlessCapable } else { $null }
        DefaultMfaMethod = if ($registration) { $registration.DefaultMfaMethod } else { $null }
        PrivilegedRoles = @($roles.RoleName)
        RoleAssignments = $roles
        ReviewPriority = $priority
        Findings = $findings
    }
}

$priorityRank = @{ Critical = 0; High = 1; Informational = 2 }
$results | Sort-Object @{ Expression = { $priorityRank[$_.ReviewPriority] } }, UserPrincipalName
