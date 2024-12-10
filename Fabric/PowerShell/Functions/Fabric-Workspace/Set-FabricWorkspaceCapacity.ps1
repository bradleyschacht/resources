function Set-FabricWorkspaceCapacity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Workspace,
        [Parameter(Mandatory = $true)] [string] $Capacity,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceDetail = Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken
    $WorkspaceID = $WorkspaceDetail.id

    if (Test-FabricID -String $Capacity) {
        $CapacityID = $Capacity
    }
    else {
        $CapacityID = (Get-FabricCapacity -Capacity $Capacity -AccessToken $AccessToken).id
    }

    if($WorkspaceDetail.capacityId -eq $CapacityID) {
        #Do nothing.
    }
    elseif ($WorkspaceDetail.capacityId -ne $CapacityID) {
        try {
            $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/assignToCapacity" -f $WorkspaceID
            $Body = '{"capacityId": "' + $CapacityID + '"}'
            $null = Invoke-FabricRestMethod -Uri $Uri -Method POST -Body $Body -AccessToken $AccessToken

            Start-Sleep -Seconds 5        

            do {

                $WorkspaceDetail = Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken -DetailOutput

                if ($WorkspaceDetail.capacityId -ne $CapacityID -or $WorkspaceDetail.CapacityAssignmentProgress -ne "Completed") {
                    Start-Sleep -Seconds 5
                }
            } until (
                $WorkspaceDetail.capacityId -eq $CapacityID -and $WorkspaceDetail.CapacityAssignmentProgress -eq "Completed"
            )
        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity or workspace in an unknown state."
    }

    $WorkspaceDetail
}