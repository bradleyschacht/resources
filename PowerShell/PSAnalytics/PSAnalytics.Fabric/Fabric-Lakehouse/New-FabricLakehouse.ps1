function New-FabricLakehouse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $false)] [string] $Description,
        [Parameter(Mandatory = $false)] [boolean] $EnableSchemas = $false,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    $CreationPayloadEnableSchemas = switch ($EnableSchemas) {
        $true {@{"enableSchemas" = "true"}}
        $false {""}
    }

    [hashtable] $BodyProperties = @{
        "displayName" = $Name
        "description" = $Description
        creationPayload = $CreationPayloadEnableSchemas
    }

    $Body = Get-FabricFilterHashtable $BodyProperties | ConvertTo-Json

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/lakehouses" -f $WorkspaceID
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
}