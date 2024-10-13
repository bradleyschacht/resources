function Get-FabricSqlConnectionString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Item,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    $Lakehouse = (Get-FabricLakehouse -Workspace $WorkspaceID -Lakehouse $Item -AccessToken $AccessToken).properties.sqlEndpointProperties.connectionString
    $Warehouse = (Get-FabricWarehouse -Workspace $WorkspaceID -Warehouse $Item -AccessToken $AccessToken).properties.connectionString
    
    if (![string]::IsNullOrEmpty($Lakehouse)) {
        $Lakehouse
    }
    elseif (![string]::IsNullOrEmpty($Warehouse)) {
        $Warehouse
    }
    else {
        "No connection string found."
    }
}