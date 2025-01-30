function Resume-FabricAzCapacity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string]$SubscriptionID,
        [Parameter(Mandatory = $true)] [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)] [string]$CapacityName,
        [Parameter(Mandatory = $false)] [string]$AccessToken,
        [Parameter(Mandatory = $false)] [string]$APIVersion = "2023-11-01"
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }

    $Capacity = Get-FabricAzCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
    
    if ($Capacity.properties.state -eq "Active") {
        #Do nothing.
    }
    elseif ($Capacity.properties.state -eq "Paused") {    
        try {
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}/resume?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $null = Invoke-FabricRestMethod -Uri $Uri -Method POST -AccessToken $AccessToken

            Start-Sleep -Seconds 5

            do {
                $Capacity = Get-FabricAzCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
                    
                if ($Capacity.properties.state -ne "Active") {
                    Start-Sleep -Seconds 5
                }
            } until (
                $Capacity.properties.state -eq "Active"
            )
        }
        catch {
            throw $_
        }
    }
    else {
        Write-Host "Capacity in an unknown state."
    }

    $Capacity
}