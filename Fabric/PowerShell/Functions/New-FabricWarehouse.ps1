function New-FabricWarehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $WarehouseName,
        [Parameter(Mandatory = $false)] [string] $WarehouseDescription,
        [Parameter(Mandatory = $false)] [boolean] $CaseSensitive = $true,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if($CaseSensitive) {
        $CaseSensitiveParameter = "Latin1_General_100_BIN2_UTF8"
    }
    else {
        $CaseSensitiveParameter = "Latin1_General_100_CI_AS_KS_WS_SC_UTF8"
    }

    if($WarehouseDescription) {
        $DescriptionParameter = ", ""description"": ""{0}""" -f $WarehouseDescription
    }
    else {
        $DescriptionParameter = ""
    }

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses" -f $WorkspaceID
    $Body = "{{""displayName"": ""{0}"",""creationPayload"":{{""defaultCollation"":""{1}""}}{2}}}" -f $WarehouseName, $CaseSensitiveParameter, $DescriptionParameter
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
}