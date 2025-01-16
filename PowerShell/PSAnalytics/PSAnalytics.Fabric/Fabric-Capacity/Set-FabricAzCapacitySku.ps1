function Set-FabricAzCapacitySku {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $SubscriptionID,
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $CapacityName,
        [Parameter(Mandatory = $true)] [ValidateSet("F2", "F4", "F8", "F16", "F32", "F64", "F128", "F256", "F512", "F1024", "F2048")] [string] $Sku,
        [Parameter(Mandatory = $false)] [string] $AccessToken,
        [Parameter(Mandatory = $false)] [string] $APIVersion = "2022-07-01-preview"
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }
        
    #Get the current SKU
    $Capacity = Get-FabricAzCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName
        
    if ($Capacity.sku.name -eq $Sku) {
        #Do nothing.
    }
    elseif ($Capacity.sku.name -ne $Sku) {
        try {
            $Uri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Body = '{"sku": {"name": "' + $Sku + '"}}'
            $null = Invoke-FabricRestMethod -Uri $Uri -Method PATCH -Body $Body -AccessToken $AccessToken

            Start-Sleep -Seconds 5

            do {
                
                $Capacity = Get-FabricAzCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion

                if ($Capacity.sku.name -ne $Sku) {
                    Start-Sleep -Seconds 5
                }
            } until (
                $Capacity.sku.name -eq $Sku
            )        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity in an unknown state."
    }

    $Capacity
}