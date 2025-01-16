function Remove-FabricLakehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Lakehouse,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    Remove-FabricItem -Workspace $Workspace -Item $Lakehouse -ItemType "Lakehouse" -AccessToken $AccessToken
}