function Get-FabricWorkspace {
    param (
        [Parameter(Mandatory = $false)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $AccessToken,
        [Parameter(Mandatory = $false)] [switch] $DetailOutput
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceList = (Invoke-FabricRestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Method GET).value

    if($Workspace) {
        if(Test-FabricId -String $Workspace) {
            $WorkspaceList = $WorkspaceList | Where-Object {$_.id -eq $Workspace}
        }
        else {
            $WorkspaceList = $WorkspaceList | Where-Object {$_.displayName -like $Workspace}
        }
    }

    if($DetailOutput) {
        foreach($WorkspaceDetail in $WorkspaceList) {
            $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}" -f $WorkspaceDetail.id
            (Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken | Select-Object * -ExpandProperty oneLakeEndpoints -ExcludeProperty oneLakeEndpoints)
        }
    }
    else {
        $WorkspaceList
    }
}