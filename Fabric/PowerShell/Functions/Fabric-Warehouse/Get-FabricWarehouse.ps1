function Get-FabricWarehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $Warehouse,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if (!$Warehouse) {
        [array]$WarehouseList = $()

        $WorkspaceItemList = Get-FabricItem -Workspace $WorkspaceID -ItemType "Warehouse" -AccessToken $AccessToken
        
         foreach ($WorkspaceItem in $WorkspaceItemList) {
             $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses/{1}" -f $WorkspaceID, $WorkspaceItem.id
             $Response = Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken
             if ($Response.id) {
                $WarehouseList += ($Response | Select-Object * -ExpandProperty properties -ExcludeProperty properties)
             }
        }

        $WarehouseList
    }

    if ($Warehouse) {
        if ((Test-FabricID -String $Warehouse)) {
            $WarehouseID = $Warehouse
        }
        else {
            $WarehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Warehouse -ItemType "Warehouse" -AccessToken $AccessToken).id
        }
        
        $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses/{1}" -f $WorkspaceID, $WarehouseID
        $Response = Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken
        if ($Response.id) {
            $Response | Select-Object * -ExpandProperty properties -ExcludeProperty properties
        }
    }
}