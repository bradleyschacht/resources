function New-FabricWorkspace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $false)] [string] $Capacity,
        [Parameter(Mandatory = $false)] [string] $Description,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    if ($Capacity) {
        if ((Test-FabricID -String $Capacity)) {
            $CapacityID = $Capacity
        }
        else {
            $CapacityID = (Get-FabricCapacity -Capacity $Capacity -AccessToken $AccessToken).id
        }
    }

    [hashtable] $BodyProperties = @{
        "displayName" = $Name
        "description" = $Description
        "capacityId"  = $CapacityID
    }

    $Body = Get-FabricFilterHashtable $BodyProperties | ConvertTo-Json

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces" -f $WorkspaceID
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
}