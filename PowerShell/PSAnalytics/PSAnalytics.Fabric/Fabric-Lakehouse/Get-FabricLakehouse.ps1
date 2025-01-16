function Get-FabricLakehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $Lakehouse,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if (!$Lakehouse) {
        [array]$LakehouseList = $()

        $WorkspaceItemList = Get-FabricItem -Workspace $WorkspaceID -ItemType "Lakehouse" -AccessToken $AccessToken
        
         foreach ($WorkspaceItem in $WorkspaceItemList) {
             $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/lakehouses/{1}" -f $WorkspaceID, $WorkspaceItem.id
             $Response = Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken
             if ($Response.id) {
                $LakehouseList += ($Response | Select-Object * -ExpandProperty properties -ExcludeProperty properties)
             }
        }

        $LakehouseList
    }

    if ($Lakehouse) {
        if ((Test-FabricID -String $Lakehouse)) {
            $LakehouseID = $Lakehouse
        }
        else {
            $LakehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Lakehouse -ItemType "Lakehouse" -AccessToken $AccessToken).id
        }
        
        $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/lakehouses/{1}" -f $WorkspaceID, $LakehouseID
        $Response = Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken
        if ($Response.id) {
            $Response | Select-Object * -ExpandProperty properties -ExcludeProperty properties
        }
    }
}