function Suspend-FabricAzCapacity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string]$SubscriptionID,
        [Parameter(Mandatory = $true)] [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)] [string]$CapacityName,
        [Parameter(Mandatory = $false)] [string]$AccessToken,
        [Parameter(Mandatory = $false)] [string]$APIVersion = "2022-07-01-preview"
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }
    
    $Capacity = Get-FabricAzCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
    
    if ($Capacity.properties.state -eq "Paused") {
        #Do nothing.
    }
    elseif ($Capacity.properties.state -eq "Active") {
        try {  
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}/suspend?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $null = Invoke-FabricRestMethod -Uri $Uri -Method POST -AccessToken $AccessToken
            
            Start-Sleep -Seconds 5

            do {
                $Capacity = Get-FabricAzCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
                    
                if ($Capacity.properties.state -ne "Paused") {
                    Start-Sleep -Seconds 5
                }
            } until (
                $Capacity.properties.state -eq "Paused"
            )
        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity in an unknown state."
    }

    $Capacity
}