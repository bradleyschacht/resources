










Clear-Host
[array]$List = @()

$WorkspaceList = Get-FabricWorkspace | Sort-Object -Property displayName

foreach ($Workspace in $WorkspaceList) {
        try {
            write-host $Workspace.displayName
            $Uri = "https://api.fabric.microsoft.com/v1/workspaces/{0}/roleAssignments" -f $Workspace.id
            
            $Permissions = (Invoke-FabricRestMethod -Uri $Uri -Method GET).value

            foreach ($Permission in $Permissions) {
                if ($Permission.Role -eq "Admin") {
                    if ($Permission.principal.type -eq "User") {
                        if ($Permission.principal.userDetails.userPrincipalName -eq "scbradl@microsoft.com") {
                            #Write-Host "I'm an admin."
                            $List += ("https://msit.fabric.microsoft.com/groups/{0}/list?experience=fabric-developer     {1}" -f $Workspace.id, $Workspace.displayName)
                            Write-Host ("https://msit.fabric.microsoft.com/groups/{0}/list?experience=fabric-developer     {1}" -f $Workspace.id, $Workspace.displayName)  -ForegroundColor Green
                        }
                    }
                }
            }
        }
        catch {
            if(($_.ErrorDetails.Message | ConvertFrom-Json).errorCode -eq "InsufficientWorkspaceRole") {
                Write-Host "Permission Denied" -ForegroundColor Red
            }
            else {
                $_
            }
        }
}



(Invoke-FabricRestMethod -Uri $Uri -Method GET).value | Where-Object{$_.role -eq "Admin"} | ConvertTo-JSON -Depth 3