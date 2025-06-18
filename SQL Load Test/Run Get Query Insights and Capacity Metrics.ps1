$LogDirectory = ""

foreach ($Directory in (Get-ChildItem -Path $LogDirectory -Directory)) {
    Write-Host " "
    Write-Host $Directory.FullName
    
    $Parameters = @{
        LogDirectory                               = $Directory.FullName
        
        # Query Insights
        QueryInsights                              = $true
        OverwriteQueryInsights                     = $true
        
        # Capacity Metrics
        CapacityMetrics                            = $true
        OverwriteCapacityMetrics                   = $true
        CapacityMetricsWorkspace                   = "Fabric Capacity Metrics"
        CapacityMetricsSemanticModelName           = "Fabric Capacity Metrics"
        
        WaitTimeInMinutesForQueryInsightsData      = 20
        WaitTimeInMinutesForCapacityMetricsData    = 20
    }
    
    Invoke-SqlLoadTestGetQueryInsightsAndCapacityMetrics @Parameters
    Write-Host " "
}