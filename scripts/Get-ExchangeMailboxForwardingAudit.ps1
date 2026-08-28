# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Audits mailbox-level forwarding in Exchange Online.
.PARAMETER IncludeNoForwarding
Includes mailboxes that do not have forwarding configured.
.EXAMPLE
./Get-ExchangeMailboxForwardingAudit.ps1 | Where-Object IsExternal
.NOTES
Requires an existing Exchange Online session and recipient read access.
#>
[CmdletBinding()]
param([switch]$IncludeNoForwarding)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'ExchangeOnlineManagement is unavailable. Install the module and run Connect-ExchangeOnline.'
}
if (-not @(Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'No Exchange Online session found. Run Connect-ExchangeOnline first.'
}

$tenantDomains = @(Get-AcceptedDomain -ErrorAction Stop | ForEach-Object { [string]$_.DomainName })
Get-EXOMailbox -ResultSize Unlimited -Properties ForwardingSmtpAddress,ForwardingAddress,DeliverToMailboxAndForward,RecipientTypeDetails,ExternalDirectoryObjectId | ForEach-Object {
    $mailbox = $_
    $target = if ($mailbox.ForwardingSmtpAddress) {
        [string]$mailbox.ForwardingSmtpAddress -replace '^smtp:', ''
    } elseif ($mailbox.ForwardingAddress) {
        [string]$mailbox.ForwardingAddress
    } else { $null }

    if (-not $target -and -not $IncludeNoForwarding) { return }
    $acceptedDomain = $null
    if ($target -match '@(.+)$') { $acceptedDomain = $Matches[1] }
    [pscustomobject]@{
        DisplayName               = $mailbox.DisplayName
        PrimarySmtpAddress        = [string]$mailbox.PrimarySmtpAddress
        RecipientTypeDetails      = $mailbox.RecipientTypeDetails
        ForwardingTarget          = $target
        DeliverToMailboxAndForward = $mailbox.DeliverToMailboxAndForward
        IsExternal                = [bool]($target -and $acceptedDomain -and $acceptedDomain -notin $tenantDomains)
        ExternalDirectoryObjectId = $mailbox.ExternalDirectoryObjectId
        ReviewRecommended         = [bool]$target
    }
}
