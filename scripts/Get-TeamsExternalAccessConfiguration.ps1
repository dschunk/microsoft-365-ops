# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Summarizes tenant-wide Microsoft Teams federation and external-access settings.
.EXAMPLE
./Get-TeamsExternalAccessConfiguration.ps1 | Format-List
.NOTES
Requires MicrosoftTeams and an existing Connect-MicrosoftTeams session.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-CsTenantFederationConfiguration -ErrorAction SilentlyContinue)) {
    throw 'MicrosoftTeams is unavailable. Install the module and run Connect-MicrosoftTeams.'
}

try {
    $config = Get-CsTenantFederationConfiguration -ErrorAction Stop
} catch {
    throw "Could not read Teams federation configuration. Connect with Connect-MicrosoftTeams and verify your role. $($_.Exception.Message)"
}

[pscustomobject]@{
    TenantId                         = $config.TenantId
    AllowFederatedUsers              = $config.AllowFederatedUsers
    AllowPublicUsers                 = $config.AllowPublicUsers
    AllowTeamsConsumer               = $config.AllowTeamsConsumer
    AllowTeamsConsumerInbound        = $config.AllowTeamsConsumerInbound
    AllowedDomains                   = (@($config.AllowedDomains.AllowedDomain) -join ';')
    BlockedDomains                   = (@($config.BlockedDomains.BlockedDomain) -join ';')
    DomainRestrictionMode            = if (@($config.AllowedDomains).Count) { 'AllowList' } elseif (@($config.BlockedDomains).Count) { 'BlockList' } else { 'Open' }
    RestrictTeamsConsumerToExternalUserProfiles = $config.RestrictTeamsConsumerToExternalUserProfiles
    CapturedAtUtc                    = (Get-Date).ToUniversalTime().ToString('o')
}
