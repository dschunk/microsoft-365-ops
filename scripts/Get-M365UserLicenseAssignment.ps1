# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Shows friendly Microsoft 365 license assignments for one user.
.PARAMETER UserPrincipalName
User principal name of the account to inspect.
.EXAMPLE
./Get-M365UserLicenseAssignment.ps1 -UserPrincipalName alex@contoso.com
.NOTES
Suggested Graph permissions: User.Read.All and Organization.Read.All.
Requires an existing Microsoft Graph session. The script does not assign or remove licenses.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'User.Read.All','Organization.Read.All'."
}

$user = Get-MgUser -UserId $UserPrincipalName -Property 'id,displayName,userPrincipalName,assignedLicenses' -ErrorAction Stop
$assigned = @($user.AssignedLicenses)

if ($assigned.Count -eq 0) {
    [pscustomobject]@{
        DisplayName       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        ObjectId          = $user.Id
        SkuId             = $null
        SkuPartNumber     = $null
        DisabledPlanCount = 0
        DisabledPlans     = @()
        Status            = 'NoAssignedLicenses'
    }
    return
}

$skuMap = @{}
try {
    foreach ($sku in @(Get-MgSubscribedSku -All -ErrorAction Stop)) {
        $skuMap[[string]$sku.SkuId] = $sku
    }
}
catch {
    throw "Unable to read tenant subscribed SKUs. Verify Organization.Read.All or equivalent access. $($_.Exception.GetBaseException().Message)"
}

foreach ($license in $assigned) {
    $skuId = [string]$license.SkuId
    $sku = $skuMap[$skuId]

    [pscustomobject]@{
        DisplayName       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        ObjectId          = $user.Id
        SkuId             = $skuId
        SkuPartNumber     = if ($sku) { $sku.SkuPartNumber } else { $null }
        ConsumedUnits     = if ($sku) { $sku.ConsumedUnits } else { $null }
        EnabledUnits      = if ($sku -and $sku.PrepaidUnits) { $sku.PrepaidUnits.Enabled } else { $null }
        DisabledPlanCount = @($license.DisabledPlans).Count
        DisabledPlans     = @($license.DisabledPlans)
        Status            = if ($sku) { 'Assigned' } else { 'AssignedSkuNotResolved' }
    }
}
