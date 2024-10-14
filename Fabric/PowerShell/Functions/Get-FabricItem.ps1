function Get-FabricItem {
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $Item,
        [Parameter(Mandatory = $false)] [ArgumentCompletions("Dashboard", "DataPipeline", "Datamart", "Environment", "Eventhouse", "Eventstream", "KQLDashboard", "KQLDatabase", "KQLQueryset", "Lakehouse", "MLExperiment", "MLModel", "MirroredWarehouse", "Notebook", "PaginatedReport", "Report", "SQLEndpoint", "SemanticModel", "SparkJobDefinition", "Warehouse")] [string] $ItemType,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    $Uri      = "https://api.fabric.microsoft.com/v1/workspaces/{0}/items" -f $WorkspaceID
    $ItemList = (Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken).value

    # Check if an item or item type were provided.
    if($Item -or $ItemType) {
        
        if($Item) {
            # If an item id was provided.
            if((Test-FabricId -String $Item)) {
                $FilteredItemList = $ItemList | Where-Object {$_.id -eq $Item}
            }
            # If an item name was provided.
            else {
                $FilteredItemList = $ItemList | Where-Object {$_.displayName -like $Item}
            }
        }
        else {
            $FilteredItemList = $ItemList
        }

        if($ItemType) {
            $FilteredItemList = $FilteredItemList | Where-Object {$_.type -like $ItemType}
        }
        
        $FilteredItemList
    }
    else {
        $ItemList
    }
}