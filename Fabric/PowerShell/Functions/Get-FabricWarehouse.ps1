function Get-FabricWarehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Warehouse,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if ((Test-FabricID -String $Warehouse)) {
        $WarehouseID = $Warehouse
    }
    else {
        $WarehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Warehouse -ItemType "Warehouse" -AccessToken $AccessToken).id
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses/{1}" -f $WorkspaceID, $WarehouseID
    Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken
}