function Get-FabricShortcutTargetOneLake {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Item,
        [Parameter(Mandatory = $true)] [ArgumentCompletions("Dashboard", "DataPipeline", "Datamart", "Environment", "Eventhouse", "Eventstream", "KQLDashboard", "KQLDatabase", "KQLQueryset", "Lakehouse", "MLExperiment", "MLModel", "MirroredWarehouse", "Notebook", "PaginatedReport", "Report", "SQLEndpoint", "SemanticModel", "SparkJobDefinition", "Warehouse")] [string] $ItemType,
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    $ItemID = (Get-FabricItem -Workspace $Workspace -Item $Item -ItemType $ItemType -AccessToken $AccessToken).id

    [hashtable] $Target = @{
        "onelake" = @{
            "workspaceId" = $WorkspaceID
            "itemId" = $ItemID
            "path" = $Path
        }
    }

    $Target
}