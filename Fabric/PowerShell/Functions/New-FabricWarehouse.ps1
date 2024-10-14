function New-FabricWarehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $WarehouseName,
        [Parameter(Mandatory = $false)] [string] $WarehouseDescription,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if($WarehouseDescription) {
        $DescriptionParameter = ", ""description"": ""{0}""" -f $WarehouseDescription
    }
    else {
        $DescriptionParameter = ""
    }

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses" -f $WorkspaceID
    $Body = "{{""displayName"": ""{0}""{1}}}" -f $WarehouseName, $DescriptionParameter
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
}