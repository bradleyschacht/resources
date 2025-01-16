function Set-FabricWarehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Warehouse,
        [Parameter(Mandatory = $false)] [string] $Name,
        [Parameter(Mandatory = $false)] [string] $Description,
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

    [hashtable] $BodyProperties = @{
        "displayName" = $Name
        "description" = $Description
    }

    $Body = Get-FabricFilterHashtable $BodyProperties | ConvertTo-Json

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses/{1}" -f $WorkspaceID, $WarehouseID
    Invoke-FabricRestMethod -Uri $Uri -Method PATCH -Body $Body -AccessToken $AccessToken
}