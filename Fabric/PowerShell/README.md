# Fabric PowerShell

```powershell
# Load the FabricPowerShell module.
New-Module -Name FabricPowerShell -ScriptBlock ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Fabric%20PowerShell.psm1")))
```

```powershell
# View a list of functions that were loaded.
Get-Command -Module "FabricPowerShell"
```
