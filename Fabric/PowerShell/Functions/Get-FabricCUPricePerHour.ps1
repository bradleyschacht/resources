function Get-FabricCUPricePerHour {
    param (
        [Parameter(Mandatory = $false)] [string] $Capacity,
        [Parameter(Mandatory = $false)] [string] $Region
    )

    if(![string]::IsNullOrEmpty($Capacity)) {
        $CapacityRegion = (Get-FabricCapacity -Location "Fabric" -Capacity $Capacity).region
    
        $Region = (Get-AzLocation | Where-Object {$_.DisplayName -eq $CapacityRegion}).Location
    }
    else {
        $Region = (Get-AzLocation | Where-Object {$_.DisplayName -eq $Region -or $_.Location -eq $Region}).Location
    }
    
    $Uri = "https://prices.azure.com/api/retail/prices?`$filter=serviceName eq 'Microsoft Fabric' and skuName eq 'Compute Pool Capacity Usage' and armRegionName eq '{0}'" -f $Region
    Invoke-FabricRestMethod -Uri $Uri
}