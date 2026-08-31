# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Summarizes recent Microsoft Entra sign-in failures into investigation-ready groups.
.PARAMETER Hours
Number of hours of sign-in history to inspect. Defaults to 24.
.PARAMETER UserPrincipalName
Optional UPN filter applied after retrieval.
.EXAMPLE
./Get-M365SignInFailureSummary.ps1 -Hours 12
.EXAMPLE
./Get-M365SignInFailureSummary.ps1 -UserPrincipalName alex@contoso.com -Hours 48
.NOTES
Suggested Graph permissions: AuditLog.Read.All. Sign-in retention depends on tenant licensing and policy.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 720)]
    [int]$Hours = 24,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'AuditLog.Read.All'."
}
if (-not (Get-Command Get-MgAuditLogSignIn -ErrorAction SilentlyContinue)) {
    throw 'Get-MgAuditLogSignIn is unavailable. Install the Microsoft.Graph.Reports module.'
}

$since = (Get-Date).ToUniversalTime().AddHours(-$Hours)
$filterTime = $since.ToString('yyyy-MM-ddTHH:mm:ssZ')
$events = @(Get-MgAuditLogSignIn -Filter "createdDateTime ge $filterTime" -All | Where-Object {
    $_.Status.ErrorCode -ne 0 -and (-not $UserPrincipalName -or $_.UserPrincipalName -ieq $UserPrincipalName)
})

$rows = @($events | ForEach-Object {
    [pscustomobject]@{
        UserPrincipalName = $_.UserPrincipalName
        UserDisplayName = $_.UserDisplayName
        AppDisplayName = $_.AppDisplayName
        ClientAppUsed = $_.ClientAppUsed
        ErrorCode = [int]$_.Status.ErrorCode
        FailureReason = [string]$_.Status.FailureReason
        AdditionalDetails = [string]$_.Status.AdditionalDetails
        ConditionalAccessStatus = [string]$_.ConditionalAccessStatus
        IPAddress = $_.IpAddress
        City = $_.Location.City
        State = $_.Location.State
        CountryOrRegion = $_.Location.CountryOrRegion
        CreatedDateTime = [datetime]$_.CreatedDateTime
        CorrelationId = $_.CorrelationId
        RiskLevelAggregated = [string]$_.RiskLevelAggregated
    }
})

$rows | Group-Object UserPrincipalName,AppDisplayName,ClientAppUsed,ErrorCode,FailureReason | ForEach-Object {
    $items = @($_.Group)
    $first = $items | Sort-Object CreatedDateTime | Select-Object -First 1
    $last = $items | Sort-Object CreatedDateTime -Descending | Select-Object -First 1
    [pscustomobject]@{
        UserPrincipalName = $first.UserPrincipalName
        UserDisplayName = $first.UserDisplayName
        AppDisplayName = $first.AppDisplayName
        ClientAppUsed = $first.ClientAppUsed
        ErrorCode = $first.ErrorCode
        FailureReason = $first.FailureReason
        AdditionalDetails = @($items.AdditionalDetails | Where-Object { $_ } | Sort-Object -Unique)
        Count = $items.Count
        FirstSeenUtc = $first.CreatedDateTime.ToUniversalTime()
        LastSeenUtc = $last.CreatedDateTime.ToUniversalTime()
        IPAddresses = @($items.IPAddress | Where-Object { $_ } | Sort-Object -Unique)
        Locations = @($items | ForEach-Object { @($_.City,$_.State,$_.CountryOrRegion) -ne $null -join ', ' } | Where-Object { $_ } | Sort-Object -Unique)
        ConditionalAccessStatuses = @($items.ConditionalAccessStatus | Where-Object { $_ } | Sort-Object -Unique)
        RiskLevels = @($items.RiskLevelAggregated | Where-Object { $_ } | Sort-Object -Unique)
        CorrelationIds = @($items.CorrelationId | Where-Object { $_ } | Sort-Object -Unique)
    }
} | Sort-Object Count -Descending,LastSeenUtc -Descending
