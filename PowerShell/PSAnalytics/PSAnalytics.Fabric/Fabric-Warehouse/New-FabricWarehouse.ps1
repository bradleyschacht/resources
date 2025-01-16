function New-FabricWarehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $false)] [string] $Description,
        [Parameter(Mandatory = $false)] [boolean] $CaseSensitive = $true,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if($CaseSensitive) {
        $DefaultCollation = "Latin1_General_100_BIN2_UTF8"
    }
    else {
        $DefaultCollation = "Latin1_General_100_CI_AS_KS_WS_SC_UTF8"
    }

    [hashtable] $BodyProperties = @{
        "displayName" = $Name
        "description" = $Description
        creationPayload = @{"defaultCollation" = $DefaultCollation}
    }

    $Body = Get-FabricFilterHashtable $BodyProperties | ConvertTo-Json

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses" -f $WorkspaceID
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
}