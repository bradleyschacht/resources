<#
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

foreach($Module in (Get-ChildItem -Path .\Functions | Where-Object {$_.Extension -eq ".ps1"})) {
    . $Module.FullName
    Export-ModuleMember -Function $Module.BaseName
}
#>


$FunctionList = @{
    "Find-FabricSQLMessage"         = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Find-FabricSQLMessage.ps1"
    "Get-FabricAccessToken"         = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricAccessToken.ps1"
    "Get-FabricCapacity"            = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricCapacity.ps1"
    "Get-FabricCapacityMetrics"     = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricCapacityMetrics.ps1"
    "Get-FabricCUPricePerHour"      = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricCUPricePerHour.ps1"
    "Get-FabricItem"                = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricItem.ps1"
    "Get-FabricLakehouse"           = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricLakehouse.ps1"
    "Get-FabricSqlConnectionString" = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricSqlConnectionString.ps1"
    "Get-FabricWarehouse"           = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricWarehouse.ps1"
    "Get-FabricWorkspace"           = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Get-FabricWorkspace.ps1"
    "Invoke-FabricRestMethod"       = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Invoke-FabricRestMethod.ps1"
    "Invoke-FabricSqlCommand"       = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Invoke-FabricSqlCommand.ps1"
    "New-FabricWorkspace"           = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/New-FabricWorkspace.ps1"
    "Remove-FabricWorkspace"        = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Remove-FabricWorkspace.ps1"
    "Resume-FabricCapacity"         = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Resume-FabricCapacity.ps1"
    "Set-FabricCapacitySku"         = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Set-FabricCapacitySku.ps1"
    "Set-FabricWorkspaceCapacity"   = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Set-FabricWorkspaceCapacity.ps1"
    "Suspend-FabricCapacity"        = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Suspend-FabricCapacity.ps1"
    "Test-FabricId"                 = "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Functions/Test-FabricId.ps1"
}

foreach($Key in $FunctionList.Keys) {
    . {Invoke-Expression (Invoke-WebRequest -Uri $FunctionList[$Key])}
    
    Export-ModuleMember -Function $Key
}