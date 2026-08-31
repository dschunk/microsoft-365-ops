# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Returns current and recent Microsoft 365 service-health incidents from Microsoft Graph.
.PARAMETER Service
Optional wildcard filter for the affected service name.
.PARAMETER Days
Number of days of service-health history to include. Defaults to 30.
.PARAMETER IncludeResolved
Includes incidents whose status indicates service restoration or resolution.
.EXAMPLE
./Get-M365ServiceHealthIncident.ps1
.EXAMPLE
./Get-M365ServiceHealthIncident.ps1 -Service '*Exchange*' -IncludeResolved
.NOTES
Suggested Graph permission: ServiceHealth.Read.All.
#>
[CmdletBinding()]
param(
    [string]$Service = '*',
    [ValidateRange(1, 365)]
    [int]$Days = 30,
    [switch]$IncludeResolved
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'ServiceHealth.Read.All'."
}
if (-not (Get-Command Get-MgServiceAnnouncementIssue -ErrorAction SilentlyContinue)) {
    throw 'Get-MgServiceAnnouncementIssue is unavailable. Install Microsoft.Graph.Devices.ServiceAnnouncement.'
}

$cutoff = (Get-Date).ToUniversalTime().AddDays(-$Days)
$resolvedStatuses = @(
    'serviceRestored',
    'postIncidentReviewPublished',
    'resolved',
    'falsePositive',
    'mitigated',
    'mitigatedExternal'
)

Get-MgServiceAnnouncementIssue -All | Where-Object {
    $serviceName = [string]$_.Service
    $lastModified = if ($_.LastModifiedDateTime) { ([datetime]$_.LastModifiedDateTime).ToUniversalTime() } else { [datetime]::MinValue }
    $status = [string]$_.Status
    $serviceName -like $Service -and
        $lastModified -ge $cutoff -and
        ($IncludeResolved -or $status -notin $resolvedStatuses)
} | ForEach-Object {
    $status = [string]$_.Status
    [pscustomobject]@{
        Id = $_.Id
        Title = $_.Title
        Service = $_.Service
        Feature = $_.Feature
        Status = $status
        Classification = [string]$_.Classification
        Origin = [string]$_.Origin
        IsActive = $status -notin $resolvedStatuses
        StartDateTime = $_.StartDateTime
        EndDateTime = $_.EndDateTime
        LastModifiedDateTime = $_.LastModifiedDateTime
        ImpactDescription = $_.ImpactDescription
        FeatureGroup = $_.FeatureGroup
        HighImpact = [bool]$_.IsHighImpact
    }
} | Sort-Object @{ Expression = 'IsActive'; Descending = $true }, @{ Expression = 'LastModifiedDateTime'; Descending = $true }
