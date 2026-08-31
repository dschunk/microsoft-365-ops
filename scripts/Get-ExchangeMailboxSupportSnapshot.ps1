# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Collects a concise Exchange Online mailbox support snapshot for one mailbox.
.PARAMETER Identity
Mailbox identity, typically the primary SMTP address or user principal name.
.EXAMPLE
./Get-ExchangeMailboxSupportSnapshot.ps1 -Identity alex@contoso.com
.NOTES
Requires an existing Exchange Online session and recipient/mailbox read access.
The script does not modify mailbox settings, rules, forwarding, quotas, or permissions.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Identity
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'ExchangeOnlineManagement is unavailable. Install the module and run Connect-ExchangeOnline.'
}
if (-not @(Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'No Exchange Online session found. Run Connect-ExchangeOnline first.'
}

$properties = @(
    'DisplayName',
    'PrimarySmtpAddress',
    'RecipientTypeDetails',
    'ExternalDirectoryObjectId',
    'EmailAddresses',
    'ForwardingSmtpAddress',
    'ForwardingAddress',
    'DeliverToMailboxAndForward',
    'ArchiveStatus',
    'LitigationHoldEnabled',
    'RetentionPolicy',
    'WhenMailboxCreated'
)

$mailbox = Get-EXOMailbox -Identity $Identity -Properties $properties -ErrorAction Stop
$statistics = $null
$statisticsError = $null

try {
    if (Get-Command Get-EXOMailboxStatistics -ErrorAction SilentlyContinue) {
        $statistics = Get-EXOMailboxStatistics -Identity $Identity -ErrorAction Stop
    }
    elseif (Get-Command Get-MailboxStatistics -ErrorAction SilentlyContinue) {
        $statistics = Get-MailboxStatistics -Identity $Identity -ErrorAction Stop
    }
    else {
        $statisticsError = 'No mailbox statistics command is available in the current session.'
    }
}
catch {
    $statisticsError = $_.Exception.GetBaseException().Message
}

$forwardingTarget = if ($mailbox.ForwardingSmtpAddress) {
    [string]$mailbox.ForwardingSmtpAddress -replace '^smtp:', ''
}
elseif ($mailbox.ForwardingAddress) {
    [string]$mailbox.ForwardingAddress
}
else {
    $null
}

[pscustomobject]@{
    DisplayName                 = $mailbox.DisplayName
    PrimarySmtpAddress          = [string]$mailbox.PrimarySmtpAddress
    RecipientTypeDetails        = $mailbox.RecipientTypeDetails
    ExternalDirectoryObjectId   = $mailbox.ExternalDirectoryObjectId
    EmailAddressCount           = @($mailbox.EmailAddresses).Count
    EmailAddresses              = @($mailbox.EmailAddresses | ForEach-Object { [string]$_ })
    ForwardingTarget            = $forwardingTarget
    DeliverToMailboxAndForward  = [bool]$mailbox.DeliverToMailboxAndForward
    ArchiveStatus               = $mailbox.ArchiveStatus
    LitigationHoldEnabled       = [bool]$mailbox.LitigationHoldEnabled
    RetentionPolicy             = $mailbox.RetentionPolicy
    WhenMailboxCreated          = $mailbox.WhenMailboxCreated
    ItemCount                   = if ($statistics) { $statistics.ItemCount } else { $null }
    TotalItemSize               = if ($statistics) { [string]$statistics.TotalItemSize } else { $null }
    TotalDeletedItemSize        = if ($statistics) { [string]$statistics.TotalDeletedItemSize } else { $null }
    LastLogonTime               = if ($statistics) { $statistics.LastLogonTime } else { $null }
    StatisticsError             = $statisticsError
    CollectedAtUtc              = (Get-Date).ToUniversalTime()
}
