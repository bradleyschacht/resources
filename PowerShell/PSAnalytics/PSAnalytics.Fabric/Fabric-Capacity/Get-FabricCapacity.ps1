function Get-FabricCapacity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [string] $Capacity,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }
    
    $Uri            = "https://api.fabric.microsoft.com/v1/capacities"
    $CapacityList   = (Invoke-FabricRestMethod -Uri $Uri -Method GET).value

    if($Capacity) {
        # If a capacity id was provided.
        if((Test-FabricId -String $Capacity)) {
            $CapacityList | Where-Object {$_.id -eq $Capacity}
        }
        # If a capacity name was provided.
        else {
            $CapacityList | Where-Object {$_.displayName -like $Capacity}
        }
    }
    else {
        $CapacityList
    }
}