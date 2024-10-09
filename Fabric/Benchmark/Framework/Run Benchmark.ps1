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

# Read in the content of the Invoke-FabricBenchmark script and run it to load the function.
(Get-Content .\Invoke-FabricBenchmark.ps1 -Raw) | Invoke-Expression

Clear-Host

<#
    # Alternatively, use the following code to load the script directly from GitHub.
    (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/Benchmark/Framework/Inovke-FabricBenchmark.ps1") | Invoke-Expression

#>

$BenchmarParameters = @{

    # Flight Control Database
    FlightControlServer    = ""
    FlightControlDatabase  = ""
    
    # Scenario Filters
    WorkspaceName   = $null
    ScenarioList    = @("")

    # Capacity Metrics
    CapacityMetricsDatasetID = ""

    # Runtime Variables
    GenerateNewScenarios                        = $true    <#  Default: $true  #>
    CollectQueryInsights                        = $true    <#  Default: $true  #>
    CollectCapacityMetrics                      = $true    <#  Default: $true  #>
    PauseOnCapacitySkuChange                    = $false   <#  Default: $false  #>
    StoreQueryResultsOnQueryRecord              = $false   <#  Default: $false  #>
    BatchTimeoutInMinutes                       = 120      <#  Default: 120 minutes  #>
    QueryRetryLimit                             = 1        <#  Default: 1 -> The query will not retry on failure.  #>
    WaitTimeInMinutesForQueryInsightsData       = 15       <#  Default: 15  minutes  #>
    WaitTimeInMinutesForCapacityMetricsData     = 15       <#  Default: 15  minutes  #>
    WaitTimeInSecondsAfterCapacitySkuChange     = 300      <#  Default: 5 minutes -> 300 seconds  #>
    WaitTimeInSecondsAfterCapacityResume        = 60       <#  Default: 1 minute  -> 60  seconds  #>

}

Invoke-FabricBenchmark @BenchmarParameters