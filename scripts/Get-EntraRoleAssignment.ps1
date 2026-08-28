# Copyright (c) David Schunk. Licensed under the MIT License.
<#
.SYNOPSIS
Inventories active Microsoft Entra directory-role assignments.
.PARAMETER RoleName
Optional wildcard filter for role display names.
.EXAMPLE
./Get-EntraRoleAssignment.ps1 -RoleName '*Administrator*'
.NOTES
Suggested Graph permissions: RoleManagement.Read.Directory and Directory.Read.All.
#>
[CmdletBinding()]
param([string]$RoleName = '*')

$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
    throw "No Microsoft Graph session found. Run Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','Directory.Read.All'."
}

$definitions = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object { $definitions[[string]$_.Id] = $_ }

Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty Principal | ForEach-Object {
    $definition = $definitions[[string]$_.RoleDefinitionId]
    if ($definition.DisplayName -notlike $RoleName) { return }
    $principal = $_.Principal
    [pscustomobject]@{
        RoleName              = $definition.DisplayName
        RoleTemplateId        = $definition.TemplateId
        AssignmentId          = $_.Id
        AssignmentType        = $_.AssignmentType
        DirectoryScopeId      = $_.DirectoryScopeId
        AppScopeId            = $_.AppScopeId
        PrincipalDisplayName  = $principal.AdditionalProperties.displayName
        PrincipalUserName     = $principal.AdditionalProperties.userPrincipalName
        PrincipalType         = $principal.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
        PrincipalId           = $_.PrincipalId
        IsPrivileged          = $definition.IsPrivileged
    }
}
