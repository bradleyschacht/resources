$Parameters = @{
    Scenario                   = ''
    WorkspaceName              = ''
    ItemName                   = ''
    CapacitySubscriptionID     = ''
    CapacityResourceGroupName  = ''
    CapacityName               = ''
    CapacitySize               = ''
    Dataset                    = ''
    DataSize                   = ''
    ThreadCount                = ''
    IterationCount             = ''
    QueryDirectory             = ''
    OutputDirectory            = ''
    
    CapacityMetricsWorkspace          = ''
    CapacityMetricsSemanticModelName  = 'Fabric Capacity Metrics'
    
    CollectQueryInsights                     = $true
    CollectCapacityMetrics                   = $true
    PauseOnCapacitySkuChange                 = $false
    StoreQueryResults                        = $false
    BatchTimeoutInMinutes                    = 120
    QueryRetryLimit                          = 0
    WaitTimeInMinutesForQueryInsightsData    = 15
    WaitTimeInMinutesForCapacityMetricsData  = 15
    WaitTimeInSecondsAfterCapacitySkuChange  = 300
    WaitTimeInSecondsAfterCapacityResume     = 60
}


Invoke-FabricBenchmark @Parameters