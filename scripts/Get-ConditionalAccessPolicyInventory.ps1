# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Creates a concise inventory of Microsoft Entra Conditional Access policies.
.PARAMETER IncludeRawJson
Adds a RawJson property containing the complete policy definition.
.EXAMPLE
./Get-ConditionalAccessPolicyInventory.ps1 | Format-Table DisplayName,State,UsersIncluded,ApplicationsIncluded
.NOTES
Suggested Graph permission: Policy.Read.All.
#>
[CmdletBinding()]
param([switch]$IncludeRawJson)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'Policy.Read.All'."
}

Get-MgIdentityConditionalAccessPolicy -All | ForEach-Object {
    $policy = $_
    $record = [ordered]@{
        DisplayName             = $policy.DisplayName
        PolicyId                = $policy.Id
        State                   = $policy.State
        CreatedDateTime         = $policy.CreatedDateTime
        ModifiedDateTime        = $policy.ModifiedDateTime
        UsersIncluded           = (@($policy.Conditions.Users.IncludeUsers) + @($policy.Conditions.Users.IncludeGroups) + @($policy.Conditions.Users.IncludeRoles) -join ';')
        UsersExcluded           = (@($policy.Conditions.Users.ExcludeUsers) + @($policy.Conditions.Users.ExcludeGroups) + @($policy.Conditions.Users.ExcludeRoles) -join ';')
        ApplicationsIncluded    = (@($policy.Conditions.Applications.IncludeApplications) -join ';')
        ApplicationsExcluded    = (@($policy.Conditions.Applications.ExcludeApplications) -join ';')
        UserRiskLevels          = (@($policy.Conditions.UserRiskLevels) -join ';')
        SignInRiskLevels        = (@($policy.Conditions.SignInRiskLevels) -join ';')
        ClientAppTypes          = (@($policy.Conditions.ClientAppTypes) -join ';')
        PlatformsIncluded       = (@($policy.Conditions.Platforms.IncludePlatforms) -join ';')
        LocationsIncluded       = (@($policy.Conditions.Locations.IncludeLocations) -join ';')
        GrantControls           = (@($policy.GrantControls.BuiltInControls) -join ';')
        GrantOperator           = $policy.GrantControls.Operator
        SessionControlsConfigured = [bool]$policy.SessionControls
    }
    if ($IncludeRawJson) { $record.RawJson = $policy | ConvertTo-Json -Depth 20 -Compress }
    [pscustomobject]$record
}
