function Invoke-FabricRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [string] $Uri,
        [Parameter(Mandatory = $false)] [ValidateSet("GET", "PATCH", "POST", "DELETE")] [string] $Method = "GET",
        [Parameter(Mandatory = $false)] [string] $Body,
        [Parameter(Mandatory = $false)] [string] $AccessToken,
        [Parameter(Mandatory = $false)] [int] $ConnectionTimeoutSeconds = 120,
        [Parameter(Mandatory = $false)] [int] $OperationTimeoutSeconds = 120
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $Headers = @{
        'Authorization' = "Bearer {0}" -f $AccessToken
        'Content-Type' = 'application/json'
    }

    $Response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -Body $Body -ConnectionTimeoutSeconds $ConnectionTimeoutSeconds -OperationTimeoutSeconds $OperationTimeoutSeconds

    if($Response.Content) {
        $response.Content | ConvertFrom-Json
    }
}