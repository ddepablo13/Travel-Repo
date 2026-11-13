# Requires an administrator-authenticated PnP.PowerShell connection to the test site.
# Creates NEW lists only and breaks inheritance before adding any application fields.
# This script intentionally stops on any existing name to avoid changing live list permissions.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)][string]$ServiceAccountLogin,
    [string]$Manifest = (Join-Path $PSScriptRoot "Lists.json")
)
$ErrorActionPreference = "Stop"
$definitions = Get-Content -Raw $Manifest | ConvertFrom-Json
$web = Get-PnPWeb
if (-not $web.Url) { throw "Connect to the approved test site first." }
$names = $definitions.PSObject.Properties.Name
foreach ($name in $names) {
    if (Get-PnPList -Identity $name -ErrorAction SilentlyContinue) {
        throw "List $name exists. No lists have been changed. Use a fresh test site."
    }
}
$service = Invoke-PnPSPRestMethod -Method Post -Url "/_api/web/ensureuser" -Content (@{logonName=$ServiceAccountLogin} | ConvertTo-Json)
$serviceId = $service.Id
if (-not $serviceId) { $serviceId = $service.d.Id }
if (-not $serviceId) { throw "Could not resolve service account." }
$role = Invoke-PnPSPRestMethod -Method Get -Url "/_api/web/roledefinitions/getbytype(5)"
$roleId = $role.Id
if (-not $roleId) { $roleId = $role.d.Id }
if (-not $roleId) { throw "Could not resolve Full Control role." }
foreach ($name in $names) {
    if (-not $PSCmdlet.ShouldProcess("$($web.Url)/$name","Create private GTAS list")) { continue }
    $list = New-PnPList -Title $name -Template GenericList -EnableVersioning
    $endpoint = "/_api/web/lists/getbytitle('$name')"
    Invoke-PnPSPRestMethod -Method Post -Url "$endpoint/breakroleinheritance(copyRoleAssignments=false,clearSubscopes=false)" | Out-Null
    Invoke-PnPSPRestMethod -Method Post -Url "$endpoint/roleassignments/addroleassignment(principalid=$serviceId,roledefid=$roleId)" | Out-Null
    Set-PnPField -List $name -Identity Title -Values @{Required=$false;Indexed=$true}
    foreach ($field in $definitions.$name.fields) {
        Add-PnPField -List $name -DisplayName $field.name -InternalName $field.name -Type $field.type | Out-Null
        if ($field.indexed) {
            Set-PnPField -List $name -Identity $field.name -Values @{Indexed=$true}
        }
        if ($field.type -eq "Note") {
            Set-PnPField -List $name -Identity $field.name -Values @{RichText=$false;AppendOnly=$false}
        }
    }
    if ($name -eq "GTASLedgerV2") {
        Set-PnPField -List $name -Identity Title -Values @{Required=$true;Indexed=$true;EnforceUniqueValues=$true}
    }
    if ($name -eq "GTASRequestsV2") {
        Set-PnPField -List $name -Identity SubmissionKey -Values @{Indexed=$true;EnforceUniqueValues=$true}
    }
    if ($name -eq "GTASPolicyV2") {
        Set-PnPField -List $name -Identity ProgramKey -Values @{Indexed=$true;EnforceUniqueValues=$true}
    }
    Write-Output "Created private list $name. Configure user permissions using SECURITY.md."
}
