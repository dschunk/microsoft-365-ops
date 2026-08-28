# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Finds enabled inbox rules that forward or redirect messages.
.PARAMETER Mailbox
One or more mailbox identities. When omitted, scans user and shared mailboxes.
.EXAMPLE
./Get-ExternalInboxRule.ps1 -Mailbox security@contoso.com
.NOTES
Requires an existing Exchange Online session. Large tenants should provide a mailbox subset.
#>
[CmdletBinding()]
param([string[]]$Mailbox)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) -or -not @(Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    throw 'No Exchange Online session found. Install ExchangeOnlineManagement and run Connect-ExchangeOnline.'
}

$acceptedDomains = @(Get-AcceptedDomain | ForEach-Object { [string]$_.DomainName })
$mailboxes = if ($Mailbox) {
    $Mailbox | ForEach-Object { Get-EXOMailbox -Identity $_ }
} else {
    Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox,SharedMailbox
}

foreach ($item in $mailboxes) {
    try {
        Get-InboxRule -Mailbox $item.PrimarySmtpAddress -ErrorAction Stop | Where-Object {
            $_.Enabled -and ($_.ForwardTo -or $_.ForwardAsAttachmentTo -or $_.RedirectTo)
        } | ForEach-Object {
            $targets = @($_.ForwardTo) + @($_.ForwardAsAttachmentTo) + @($_.RedirectTo)
            $targetText = @($targets | ForEach-Object { [string]$_ })
            $external = @($targetText | Where-Object {
                if ($_ -match '@([^>\s]+)') { $Matches[1].TrimEnd('>') -notin $acceptedDomains } else { $false }
            })
            [pscustomobject]@{
                Mailbox          = [string]$item.PrimarySmtpAddress
                RuleName         = $_.Name
                RuleIdentity     = $_.Identity
                Priority         = $_.Priority
                Enabled          = $_.Enabled
                ForwardTo        = (@($_.ForwardTo) -join ';')
                ForwardAsAttachmentTo = (@($_.ForwardAsAttachmentTo) -join ';')
                RedirectTo       = (@($_.RedirectTo) -join ';')
                DeleteMessage    = $_.DeleteMessage
                StopProcessingRules = $_.StopProcessingRules
                HasExternalTarget = [bool]$external.Count
                ExternalTargets  = ($external -join ';')
            }
        }
    } catch {
        Write-Error "Could not inspect inbox rules for $($item.PrimarySmtpAddress): $($_.Exception.Message)"
    }
}
