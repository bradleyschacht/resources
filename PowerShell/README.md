# Analytics PowerShell

## Adding Analytics PowerShell Module to Your PowerShell Profile
1. Open your PowerShell profile in notepad by typing following command:
```powershell
notepad $PROFILE
```
2. Add the following line of code to the profile, replacing the path to match the module's location on your computer.
```powershell
Import-Module "C:\GitHub\resources\PowerShell\PSAnalytics" -Force
```
3. Save the profile.
4. Restart the terminal.
5. Verify the Analytics PowerShell module was loaded successfully by running the following command.
``` powershell
Get-Module -Name "Analytics PowerShell"
```

## Function Documentation

### Find-FabricSQLMessage
```powershell
$SqlScriptOutput = "Statement ID: {1AF6F23F-6081-4F59-8A64-CB4A987C5372} | Query hash: 0x16A80BCAFB88F120 | Distributed request ID: {12048D04-EBED-4D74-A8D2-ED5880FE9FAF}"

Find-FabricSQLMessage -Message $SqlScriptOutput
```

### Get-FabricAccessToken
```powershell
Get-FabricAccessToken -ResourceType "Azure"
```
```powershell
Get-FabricAccessToken -ResourceType "Fabric"
```
```powershell
Get-FabricAccessToken -ResourceType "SQL"
```

### Get-FabricCapacity
```powershell
# Using the capacity name.
Get-FabricCapacity -Location Fabric -Capacity "mycapacity01"
```

```powershell
# Using the capacity id.
Get-FabricCapacity -Location Fabric -Capacity "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
```

```powershell
# Get capacity information from Azure.
Get-FabricCapacity -Location "Azure" -SubscriptionID "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" -ResourceGroupName "myresourcegroup-rg" -Capacity "mycapacity01"
```

### Get-FabricCapacityMetrics
```powershell
# By providing the workspace and semantic model name for Capacity Metrics, the script will lookup the semantic model id. For the workspace, provide either the workspace name/id or the capacity name/id to which the workspace is associated. 
$OperationIdList = @("AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", "12345678-1234-1234-1234-123456789012")

Get-FabricCapacityMetrics -CapacityMetricsWorkspace "Fabric Capacity Metrics" -CapacityMetricsSemanticModelName "Fabric Capacity Metrics" -Workspace "My Fabric Workspace" -OperationIdList $OperationIdList -Date "2000-01-01"
```

```powershell
# By providing the semantic model id for Capacity Metrics. For the workspace, provide either the workspace name/id or the capacity name/id to which the workspace is associated. 
$OperationIdList = @("AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", "12345678-1234-1234-1234-123456789012")

Get-FabricCapacityMetrics -CapacityMetricsSemanticModelId "12345678-1234-1234-1234-123456789012" -Capacity "12345678-1234-1234-1234-123456789012" -OperationIdList $OperationIdList -Date "2000-01-01"
```

### Get-FabricCUPricePerHour
```powershell
# Priovide a region to lookup the CU Price Per Hour.
Get-FabricCUPricePerHour -Region "eastus"
```

```powershell
# Provide a capacity name or id and the script will look for the region where the capacity is deployed and return the CU Price Per Hour for that region.
Get-FabricCUPricePerHour -Capacity "mycapacity01"
```

### More functions to be added.
