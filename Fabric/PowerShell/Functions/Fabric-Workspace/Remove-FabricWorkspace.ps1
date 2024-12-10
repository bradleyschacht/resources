function Remove-FabricWorkspace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceId = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}" -f $WorkspaceId
    Invoke-FabricRestMethod -Uri $Uri -Method DELETE -AccessToken $AccessToken
}