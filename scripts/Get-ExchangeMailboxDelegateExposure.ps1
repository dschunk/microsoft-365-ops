# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Inventories non-self mailbox delegation across user and shared mailboxes.
.PARAMETER Mailbox
Optional mailbox identity. When omitted, scans selected mailbox types.
.PARAMETER RecipientTypeDetails
Mailbox types to scan. Defaults to UserMailbox and SharedMailbox.
.PARAMETER TrusteePattern
Optional wildcard filter for delegate / trustee identity.
.PARAMETER IncludeInherited
Includes inherited permission entries. Direct assignments are returned by default.
.EXAMPLE
./Get-ExchangeMailboxDelegateExposure.ps1 | Sort-Object Trustee,Mailbox
.EXAMPLE
./Get-ExchangeMailboxDelegateExposure.ps1 -TrusteePattern '*admin*'
.NOTES
Requires an existing Exchange Online session and permission to read mailbox and recipient permissions.
#>
[CmdletBinding()]
param(
    [string]$Mailbox,
    [ValidateSet('UserMailbox','SharedMailbox','RoomMailbox','EquipmentMailbox')]
    [string[]]$RecipientTypeDetails = @('UserMailbox','SharedMailbox'),
    [string]$TrusteePattern = '*',
    [switch]$IncludeInherited
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) -or -not @(Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'No Exchange Online session found. Install ExchangeOnlineManagement and run Connect-ExchangeOnline.'
}

$mailboxes = if ($Mailbox) {
    @(Get-EXOMailbox -Identity $Mailbox -Properties GrantSendOnBehalfTo)
}
else {
    @(Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $RecipientTypeDetails -Properties GrantSendOnBehalfTo)
}

foreach ($item in $mailboxes) {
    $mailboxAddress = [string]$item.PrimarySmtpAddress
    $mailboxType = [string]$item.RecipientTypeDetails

    Get-EXOMailboxPermission -Identity $mailboxAddress | Where-Object {
        ($IncludeInherited -or -not $_.IsInherited) -and
        $_.User -notmatch 'NT AUTHORITY\\SELF' -and
        ([string]$_.User) -like $TrusteePattern
    } | ForEach-Object {
        [pscustomobject]@{
            Mailbox = $mailboxAddress
            DisplayName = $item.DisplayName
            MailboxType = $mailboxType
            PermissionType = 'FullAccess'
            Trustee = [string]$_.User
            AccessRights = (@($_.AccessRights) -join ';')
            Deny = [bool]$_.Deny
            Inherited = [bool]$_.IsInherited
            ReviewRecommended = -not $_.Deny
        }
    }

    Get-RecipientPermission -Identity $mailboxAddress | Where-Object {
        ($IncludeInherited -or -not $_.IsInherited) -and
        $_.Trustee -notmatch 'NT AUTHORITY\\SELF' -and
        ([string]$_.Trustee) -like $TrusteePattern
    } | ForEach-Object {
        [pscustomobject]@{
            Mailbox = $mailboxAddress
            DisplayName = $item.DisplayName
            MailboxType = $mailboxType
            PermissionType = 'SendAs'
            Trustee = [string]$_.Trustee
            AccessRights = (@($_.AccessRights) -join ';')
            Deny = [bool]$_.Deny
            Inherited = [bool]$_.IsInherited
            ReviewRecommended = -not $_.Deny
        }
    }

    foreach ($trustee in @($item.GrantSendOnBehalfTo)) {
        if ([string]$trustee -notlike $TrusteePattern) { continue }
        [pscustomobject]@{
            Mailbox = $mailboxAddress
            DisplayName = $item.DisplayName
            MailboxType = $mailboxType
            PermissionType = 'SendOnBehalf'
            Trustee = [string]$trustee
            AccessRights = 'SendOnBehalf'
            Deny = $false
            Inherited = $false
            ReviewRecommended = $true
        }
    }
}
