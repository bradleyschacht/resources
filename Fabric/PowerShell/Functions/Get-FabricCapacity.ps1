function Get-FabricCapacity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [ValidateSet("Azure", "Fabric")] [string] $Location = "Fabric",
        [Parameter(Mandatory = $false)] [string] $SubscriptionID,
        [Parameter(Mandatory = $false)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $false)] [string] $Capacity,
        [Parameter(Mandatory = $false)] [string] $AccessToken,
        [Parameter(Mandatory = $false)] [string] $APIVersion = "2022-07-01-preview"
    )

    if($Location -eq "Fabric") {
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

    if($Location -eq "Azure") {
        if ([string]::IsNullOrEmpty($AccessToken)) { 
            $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
        }

        $Uri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities?api-version={2}" -f $SubscriptionID, $ResourceGroupName, $APIVersion
        (Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken).value | Where-Object {$_.name -like $Capacity}
    }
}