function Get-FabricLakehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Lakehouse,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    if ((Test-FabricID -String $Lakehouse)) {
        $LakehouseID = $Lakehouse
    }
    else {
        $LakehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Lakehouse -ItemType "Lakehouse" -AccessToken $AccessToken).id
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/lakehouses/{1}" -f $WorkspaceID, $LakehouseID
    Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken
}