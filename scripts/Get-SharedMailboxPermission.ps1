# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Reports Full Access, Send As, and Send on Behalf permissions for shared mailboxes.
.PARAMETER Mailbox
Optional shared mailbox identity. When omitted, scans all shared mailboxes.
.EXAMPLE
./Get-SharedMailboxPermission.ps1 | Where-Object Trustee -notmatch 'NT AUTHORITY'
.NOTES
Requires an existing Exchange Online session and permission to read recipients.
#>
[CmdletBinding()]
param([string]$Mailbox)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) -or -not @(Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'No Exchange Online session found. Install ExchangeOnlineManagement and run Connect-ExchangeOnline.'
}

$mailboxes = if ($Mailbox) {
    @(Get-EXOMailbox -Identity $Mailbox)
} else {
    @(Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails SharedMailbox -Properties GrantSendOnBehalfTo)
}

foreach ($item in $mailboxes) {
    Get-EXOMailboxPermission -Identity $item.PrimarySmtpAddress | Where-Object {
        -not $_.IsInherited -and $_.User -notmatch 'NT AUTHORITY\\SELF'
    } | ForEach-Object {
        [pscustomobject]@{
            Mailbox          = [string]$item.PrimarySmtpAddress
            DisplayName      = $item.DisplayName
            PermissionType   = 'FullAccess'
            Trustee          = [string]$_.User
            AccessRights     = (@($_.AccessRights) -join ';')
            Deny             = $_.Deny
            Inherited        = $_.IsInherited
        }
    }

    Get-RecipientPermission -Identity $item.PrimarySmtpAddress | Where-Object {
        -not $_.IsInherited -and $_.Trustee -notmatch 'NT AUTHORITY\\SELF'
    } | ForEach-Object {
        [pscustomobject]@{
            Mailbox          = [string]$item.PrimarySmtpAddress
            DisplayName      = $item.DisplayName
            PermissionType   = 'SendAs'
            Trustee          = [string]$_.Trustee
            AccessRights     = (@($_.AccessRights) -join ';')
            Deny             = $_.Deny
            Inherited        = $_.IsInherited
        }
    }

    foreach ($trustee in @($item.GrantSendOnBehalfTo)) {
        [pscustomobject]@{
            Mailbox          = [string]$item.PrimarySmtpAddress
            DisplayName      = $item.DisplayName
            PermissionType   = 'SendOnBehalf'
            Trustee          = [string]$trustee
            AccessRights     = 'SendOnBehalf'
            Deny             = $false
            Inherited        = $false
        }
    }
}
