function New-FabricWorkspace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $WorkspaceName,
        [Parameter(Mandatory = $false)] [string] $WorkspaceDescription,
        [Parameter(Mandatory = $false)] [string] $Capacity,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    if ($Capacity) {
        if (Test-FabricId -String $Capacity) {
            $CapacityID = $Capacity
        }
        else {
            $CapacityID = (Get-FabricCapacity -Location "Fabric" -Capacity $Capacity -AccessToken $AccessToken).id
        }

        $CapacityParameter = ",""capacityId"": ""{0}""" -f $CapacityID
    }
    else {
        $CapacityParameter = ""
    }

    if($WorkspaceDescription) {
        $DescriptionParameter = ", ""description"": ""{0}""" -f $WorkspaceDescription
    }
    else {
        $DescriptionParameter = ""
    }

    $Uri = "https://api.fabric.microsoft.com/v1/workspaces"
    $Body = "{{""displayName"": ""{0}""{1}{2}}}" -f $WorkspaceName, $CapacityParameter, $DescriptionParameter
    Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken
}