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

    try {
        $Response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -Body $Body -ConnectionTimeoutSeconds $ConnectionTimeoutSeconds -OperationTimeoutSeconds $OperationTimeoutSeconds
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 429) {
            $RetryAfter = ($_.Exception.Response.Headers.GetValues("Retry-After") | Out-String).trim()
            
            Write-Host ("Status code 429 (Too many requests). Retrying in {0} seconds..." -f $RetryAfter) -BackgroundColor "Black" -ForegroundColor "Yellow"
            
            Start-Sleep -Seconds $RetryAfter
        } else {
            throw $_.Exception.Response
        }
    }

    if ($Response.StatusCode -eq 200) {
        if ($Response.Content) {
            $Response.Content | ConvertFrom-Json
        }
    }

    elseif ($Response.StatusCode -eq 202) {
        $StatusLocation = ($Response.Headers.Location | Out-String)

        if ($StatusLocation -ne "" -and $null -ne $StatusLocation) {
            
            do {
                $Status = (Invoke-FabricRestMethod -Uri $StatusLocation -Method GET).status
                Write-Host ("The current status is {0}" -f $Status)

                if ($Status -eq "Running") {
                    Start-Sleep -Seconds 5
                }
            } while ($Status -eq "Running")
        }

        $Response
    }

    else {
        $Response
    }
}