# Script to the current folder location was taken from this kind person's Reddit post: https://www.reddit.com/r/PowerShell/comments/b72t27/path_to_this_script_check_ise_vscode_and_running/
$PathToScript = if ($PSScriptRoot) {
    # Console or vscode debug/run button/F5 temp console
    $PSScriptRoot
}
else {
    if ($psISE) {Split-Path -Path $psISE.CurrentFile.FullPath}
    else {
        if ($profile -match "VScode") {
            # vscode "Run Code Selection" button/F8 in integrated console
            Split-Path $psEditor.GetEditorContext().CurrentFile.Path
        }
        else {
            Write-Output "unknown directory to set path variable. exiting script."
            exit
        }
    }
}

# Change the location to the folder where the scripts are stored. 
Set-Location $PathToScript

$FunctionList = @{
    # Fabric-Capacity
    "Get-FabricAzCapacity"     = ".\Functions\Fabric-Capacity\Get-FabricAzCapacity.ps1"
    "Get-FabricCapacity"       = ".\Functions\Fabric-Capacity\Get-FabricCapacity.ps1"
    "Resume-FabricAzCapacity"  = ".\Functions\Fabric-Capacity\Resume-FabricAzCapacity.ps1"
    "Set-FabricAzCapacitySku"  = ".\Functions\Fabric-Capacity\Set-FabricAzCapacitySku.ps1"
    "Suspend-FabricAzCapacity" = ".\Functions\Fabric-Capacity\Suspend-FabricAzCapacity.ps1"

    # Fabric-Core
    "Find-FabricSQLMessage"       = ".\Functions\Fabric-Core\Find-FabricSQLMessage.ps1"
    "Get-FabricAccessToken"       = ".\Functions\Fabric-Core\Get-FabricAccessToken.ps1"
    "Get-FabricFilterHashtable"   = ".\Functions\Fabric-Core\Get-FabricFilterHashtable.ps1"
    "Invoke-FabricRestMethod"     = ".\Functions\Fabric-Core\Invoke-FabricRestMethod.ps1"
    "Invoke-FabricSqlCommand"     = ".\Functions\Fabric-Core\Invoke-FabricSqlCommand.ps1"
    "Test-FabricId"               = ".\Functions\Fabric-Core\Test-FabricId.ps1"

    # Fabric-Item
    "Get-FabricItem"     = ".\Functions\Fabric-Item\Get-FabricItem.ps1"
    "Remove-FabricItem"  = ".\Functions\Fabric-Item\Remove-FabricItem.ps1"

    # Fabric-Lakehouse
    "Get-FabricLakehouse"      = ".\Functions\Fabric-Lakehouse\Get-FabricLakehouse.ps1"
    "New-FabricLakehouse"      = ".\Functions\Fabric-Lakehouse\New-FabricLakehouse.ps1"
    "Remove-FabricLakehouse"   = ".\Functions\Fabric-Lakehouse\Remove-FabricLakehouse.ps1"
    "Set-FabricLakehouse"      = ".\Functions\Fabric-Lakehouse\Set-FabricLakehouse.ps1"

    # Fabric-OneLake
    "Get-FabricShortcutTargetOneLake"   = ".\Functions\Fabric-OneLake\Get-FabricShortcutTargetOneLake.ps1"
    "New-FabricShortcut"                = ".\Functions\Fabric-OneLake\New-FabricShortcut.ps1"
    
    # Fabric-Utilities
    "Get-FabricCapacityMetrics"  = ".\Functions\Fabric-Utilities\Get-FabricCapacityMetrics.ps1"
    "Get-FabricCUPricePerHour"   = ".\Functions\Fabric-Utilities\Get-FabricCUPricePerHour.ps1"
    #"Workspaces where I'm an admin"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Utilities.ps1"

    # Fabric-Warehouse
    "Get-FabricWarehouse"     = ".\Functions\Fabric-Warehouse\Get-FabricWarehouse.ps1"
    "New-FabricWarehouse"     = ".\Functions\Fabric-Warehouse\New-FabricWarehouse.ps1"
    "Remove-FabricWarehouse"  = ".\Functions\Fabric-Warehouse\Remove-FabricWarehouse.ps1"
    "Set-FabricWarehouse"     = ".\Functions\Fabric-Warehouse\Set-FabricWarehouse.ps1"

    # Fabric-Workspace
    "Get-FabricWorkspace"          = ".\Functions\Fabric-Workspace\Get-FabricWorkspace.ps1"
    "New-FabricWorkspace"          = ".\Functions\Fabric-Workspace\New-FabricWorkspace.ps1"
    "Remove-FabricWorkspace"       = ".\Functions\Fabric-Workspace\Remove-FabricWorkspace.ps1"
    "Set-FabricWorkspaceCapacity"  = ".\Functions\Fabric-Workspace\Set-FabricWorkspaceCapacity.ps1"
}

Clear-host
foreach($Key in $FunctionList.Keys) {
    . {Invoke-Expression (Get-Content -Path $FunctionList[$Key] -Raw)}
    "Loaded {0} from {1}" -f $Key, $FunctionList[$Key]
}