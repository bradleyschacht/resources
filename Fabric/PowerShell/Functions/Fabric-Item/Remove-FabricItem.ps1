function Remove-FabricItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Item,
        [Parameter(Mandatory = $true)] [ArgumentCompletions("Dashboard", "DataPipeline", "Datamart", "Environment", "Eventhouse", "Eventstream", "KQLDashboard", "KQLDatabase", "KQLQueryset", "Lakehouse", "MLExperiment", "MLModel", "MirroredWarehouse", "Notebook", "PaginatedReport", "Report", "SQLEndpoint", "SemanticModel", "SparkJobDefinition", "Warehouse")] [string] $ItemType,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceId = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    $ItemID = (Get-FabricItem -Workspace $WorkspaceId -Item $Item -ItemType $ItemType).id

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/items/{1}" -f $WorkspaceId, $ItemID
    Invoke-FabricRestMethod -Uri $Uri -Method DELETE -AccessToken $AccessToken
}