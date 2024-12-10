function Get-FabricAzCapacity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $SubscriptionID,
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $CapacityName,
        [Parameter(Mandatory = $false)] [string] $AccessToken,
        [Parameter(Mandatory = $false)] [string] $APIVersion = "2022-07-01-preview"
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }

    $Uri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities?api-version={2}" -f $SubscriptionID, $ResourceGroupName, $APIVersion
    (Invoke-FabricRestMethod -Uri $Uri -Method GET -AccessToken $AccessToken).value | Where-Object {$_.name -like $CapacityName}
}