
clear-host
$Parameters = @{
    <#*****     Fabric Workspace Filter     *****#>
    "WorkspaceName"      = ""

    <#*****     Flight Control Database     *****#>
    "FlightControlServer"         = "scbradlsql01.database.windows.net"
    "FlightControlDatabase"       = "FlightControl"

    <#*****     Log Storage Location     *****#>

    "BatchLogFolder"     = "C:\Logging\Batch\"
    "ThreadLogFolder"    = "C:\Logging\Thread\"
    "IterationLogFolder" = "C:\Logging\Iteration\"

    "CapacityMetricsDatasetID" = "287f17e3-a624-4663-9dd8-c4f521edced2"

    <#*****     Runtime Variables     *****#>
    "GenerateNewBatches"                        = $true  <#  Default: $false  #>
    "CollectQueryInsights"                      = $true  <#  Default: $true  #>
    "CollectCapacityMetrics"                    = $true  <#  Default: $true  #>
    "PauseOnCapacitySizeChange"                 = $false <#  Default: $false  #>
    "StoreQueryResultsOnIterationRecord"        = $false <#  Default: $false  #>
    "QueryRetryLimit"                           = 2      <#  Default: 1 -> The batch will not retry on failure.  #>
    "BatchTimeoutInMinutes"                     = 120    <#  Default: 120 minutes  #>
    "WaitTimeInMinutesForQueryInsightsData"     = 15     <#  Default: 15 minutes #>
    "WaitTimeInMinutesForCapacityMetricsData"   = 15     <#  Default: 15 minutes #>
    "WaitTimeInSecondsAfterCapacitySkuChange"   = 300    <#  Default: 5 minutes -> 300 seconds  #>
    "WaitTimeInSecondsAfterCapacityResume"      = 60     <#  Default: 1 minute -> 60 seconds #>
    "WaitTimeInSecondsToRefreshConsole"         = 30     <#  Default: 1 minute -> 60 seconds #>
}

$ScriptLocation = "C:\Users\scbradl\OneDrive - Microsoft\The Correct Stuff\Framework\Framework.ps1"

.$ScriptLocation @Parameters