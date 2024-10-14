function Get-FabricSqlEndpoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/sqlEndpoints" -f $WorkspaceID
    (Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken).value
}