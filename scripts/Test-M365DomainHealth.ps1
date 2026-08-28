# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Reports Microsoft 365 domain verification and service configuration state.
.PARAMETER IncludeDnsRecords
Adds Microsoft Graph verification DNS records to each result.
.EXAMPLE
./Test-M365DomainHealth.ps1 -IncludeDnsRecords | Where-Object HealthStatus -ne 'Healthy'
.NOTES
Suggested Graph permission: Domain.Read.All.
#>
[CmdletBinding()]
param([switch]$IncludeDnsRecords)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'Domain.Read.All'."
}

Get-MgDomain -All | ForEach-Object {
    $domain = $_
    $records = @()
    if ($IncludeDnsRecords) {
        try { $records = @(Get-MgDomainVerificationDnsRecord -DomainId $domain.Id -All -ErrorAction Stop) }
        catch { Write-Warning "Could not retrieve verification DNS records for $($domain.Id): $($_.Exception.Message)" }
    }
    [pscustomobject]@{
        DomainId          = $domain.Id
        IsDefault         = $domain.IsDefault
        IsInitial         = $domain.IsInitial
        IsRoot            = $domain.IsRoot
        IsVerified        = $domain.IsVerified
        AuthenticationType = $domain.AuthenticationType
        AvailabilityStatus = $domain.AvailabilityStatus
        SupportedServices = (@($domain.SupportedServices) -join ';')
        HealthStatus      = if (-not $domain.IsVerified) { 'Unverified' } elseif ($domain.AvailabilityStatus -and $domain.AvailabilityStatus -ne 'AvailableImmediately') { 'Review' } else { 'Healthy' }
        VerificationDnsRecords = if ($IncludeDnsRecords) { $records | ConvertTo-Json -Depth 8 -Compress } else { $null }
    }
}
