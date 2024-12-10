function New-FabricShortcut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Item,
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [hashtable] $Target,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    $ItemID = (Get-FabricItem -Workspace $Workspace -Item $Item -ItemType "Lakehouse" -AccessToken $AccessToken).id

    [hashtable] $BodyProperties = @{
        "path" = $Path
        "name" = $Name
        "target" = $Target
    }

    $Body = Get-FabricFilterHashtable $BodyProperties | ConvertTo-Json

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/items/{1}/shortcuts" -f $WorkspaceID, $ItemID
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
    #$Body
}