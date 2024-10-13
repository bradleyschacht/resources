# Fabric PowerShell

New-Module -Name Fabric -ScriptBlock ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Fabric%20PowerShell.psm1")))
Get-Command -Module "Fabric"
