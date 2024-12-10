
<#
. {Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Load Fabric Functions.ps1")}
#>

$FunctionList = @{
    # Fabric-Capacity
    "Get-FabricAzCapacity"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Capacity/Get-FabricAzCapacity.ps1"
    "Get-FabricCapacity"       = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Capacity/Get-FabricCapacity.ps1"
    "Resume-FabricAzCapacity"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Capacity/Resume-FabricAzCapacity.ps1"
    "Set-FabricAzCapacitySku"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Capacity/Set-FabricAzCapacitySku.ps1"
    "Suspend-FabricAzCapacity" = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Capacity/Suspend-FabricAzCapacity.ps1"

    # Fabric-Core
    "Find-FabricSQLMessage"       = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Core/Find-FabricSQLMessage.ps1"
    "Get-FabricAccessToken"       = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Core/Get-FabricAccessToken.ps1"
    "Get-FabricFilterHashtable"   = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Core/Get-FabricFilterHashtable.ps1"
    "Invoke-FabricRestMethod"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Core/Invoke-FabricRestMethod.ps1"
    "Invoke-FabricSqlCommand"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Core/Invoke-FabricSqlCommand.ps1"
    "Test-FabricId"               = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Core/Test-FabricId.ps1"

    # Fabric-Item
    "Get-FabricItem"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Item/Get-FabricItem.ps1"
    "Remove-FabricItem"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Item/Remove-FabricItem.ps1"

    # Fabric-Lakehouse
    "Get-FabricLakehouse"      = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Lakehouse/Get-FabricLakehouse.ps1"
    "New-FabricLakehouse"      = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Lakehouse/New-FabricLakehouse.ps1"
    "Remove-FabricLakehouse"   = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Lakehouse/Remove-FabricLakehouse.ps1"
    "Set-FabricLakehouse"      = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Lakehouse/Set-FabricLakehouse.ps1"

    # Fabric-OneLake
    "Get-FabricShortcutTargetOneLake"   = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-OneLake/Get-FabricShortcutTargetOneLake.ps1"
    "New-FabricShortcut"                = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-OneLake/New-FabricShortcut.ps1"
    
    # Fabric-Utilities
    "Get-FabricCapacityMetrics"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Utilities/Get-FabricCapacityMetrics.ps1"
    "Get-FabricCUPricePerHour"   = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Utilities/Get-FabricCUPricePerHour.ps1"
    #"Workspaces where I'm an admin"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Utilities.ps1"

    # Fabric-Warehouse
    "Get-FabricWarehouse"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Warehouse/Get-FabricWarehouse.ps1"
    "New-FabricWarehouse"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Warehouse/New-FabricWarehouse.ps1"
    "Remove-FabricWarehouse"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Warehouse/Remove-FabricWarehouse.ps1"
    "Set-FabricWarehouse"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Warehouse/Set-FabricWarehouse.ps1"

    # Fabric-Workspace
    "Get-FabricWorkspace"          = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Workspace/Get-FabricWorkspace.ps1"
    "New-FabricWorkspace"          = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Workspace/New-FabricWorkspace.ps1"
    "Remove-FabricWorkspace"       = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Workspace/Remove-FabricWorkspace.ps1"
    "Set-FabricWorkspaceCapacity"  = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Fabric-Workspace/Set-FabricWorkspaceCapacity.ps1"
}

Clear-host
foreach($Key in $FunctionList.Keys) {
    . {Invoke-Expression (Invoke-WebRequest -Uri $FunctionList[$Key])}
    "Loaded {0} from {1}" -f $Key, $FunctionList[$Key]
}
