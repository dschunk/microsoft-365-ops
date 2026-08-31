# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Audits Exchange Online mail-flow rules with emphasis on routing and message-handling actions.
.PARAMETER Name
Optional wildcard filter for transport-rule names.
.PARAMETER OnlyReviewRecommended
Returns only rules with routing, deletion, rejection, or external-recipient actions that merit manual review.
.EXAMPLE
./Get-ExchangeTransportRuleAudit.ps1
.EXAMPLE
./Get-ExchangeTransportRuleAudit.ps1 -OnlyReviewRecommended | Export-Csv ./transport-rule-review.csv -NoTypeInformation
.NOTES
Requires an existing Exchange Online session and permission to read transport rules and accepted domains.
#>
[CmdletBinding()]
param(
    [string]$Name = '*',
    [switch]$OnlyReviewRecommended
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'ExchangeOnlineManagement is unavailable. Install the module and run Connect-ExchangeOnline.'
}
if (-not @(Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'No Exchange Online session found. Run Connect-ExchangeOnline first.'
}
if (-not (Get-Command Get-TransportRule -ErrorAction SilentlyContinue)) {
    throw 'Get-TransportRule is unavailable in the current Exchange Online session.'
}

$tenantDomains = @(Get-AcceptedDomain -ErrorAction Stop | ForEach-Object { ([string]$_.DomainName).ToLowerInvariant() })

function Get-ExternalTargets {
    param([object[]]$Targets)
    @($Targets | ForEach-Object {
        $value = [string]$_
        if ($value -match '@([^>\s]+)$') {
            $domain = $Matches[1].TrimEnd('>').ToLowerInvariant()
            if ($domain -notin $tenantDomains) { $value }
        }
    } | Where-Object { $_ } | Sort-Object -Unique)
}

Get-TransportRule -ErrorAction Stop | Where-Object { $_.Name -like $Name } | ForEach-Object {
    $rule = $_
    $redirect = @($rule.RedirectMessageTo | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $bcc = @($rule.BlindCopyTo | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $copy = @($rule.CopyTo | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $addTo = @($rule.AddToRecipients | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $externalTargets = @(Get-ExternalTargets -Targets @($redirect + $bcc + $copy + $addTo))

    $reviewReasons = @()
    if ($redirect.Count -gt 0) { $reviewReasons += 'Redirects message' }
    if ($bcc.Count -gt 0) { $reviewReasons += 'Blind-copies recipient' }
    if ($copy.Count -gt 0) { $reviewReasons += 'Copies recipient' }
    if ($addTo.Count -gt 0) { $reviewReasons += 'Adds recipient' }
    if ($externalTargets.Count -gt 0) { $reviewReasons += 'Routes or copies mail to an external domain' }
    if ($rule.DeleteMessage) { $reviewReasons += 'Deletes message' }
    if ($rule.RejectMessageReasonText -or $rule.RejectMessageEnhancedStatusCode) { $reviewReasons += 'Rejects message' }
    if ($rule.Quarantine) { $reviewReasons += 'Quarantines message' }

    $output = [pscustomobject]@{
        Name = $rule.Name
        State = [string]$rule.State
        Mode = [string]$rule.Mode
        Priority = $rule.Priority
        Description = $rule.Description
        Comments = $rule.Comments
        FromScope = [string]$rule.FromScope
        SentToScope = [string]$rule.SentToScope
        RedirectMessageTo = $redirect
        BlindCopyTo = $bcc
        CopyTo = $copy
        AddToRecipients = $addTo
        ExternalTargets = $externalTargets
        DeleteMessage = [bool]$rule.DeleteMessage
        RejectMessageReasonText = $rule.RejectMessageReasonText
        RejectMessageEnhancedStatusCode = $rule.RejectMessageEnhancedStatusCode
        Quarantine = [bool]$rule.Quarantine
        StopRuleProcessing = [bool]$rule.StopRuleProcessing
        ReviewRecommended = $reviewReasons.Count -gt 0
        ReviewReasons = $reviewReasons
        WhenChanged = $rule.WhenChanged
    }

    if (-not $OnlyReviewRecommended -or $output.ReviewRecommended) { $output }
} | Sort-Object Priority
