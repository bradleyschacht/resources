$Parameters = @{
    Scenario                   = 'MyTestScenario'
    WorkspaceName              = 'Brad - Sandbox'
    ItemName                   = 'MyDataWarehouse'
    CapacitySubscriptionID     = '7e416de3-c506-4776-8270-83fd73c6cc37'
    CapacityResourceGroupName  = 'scbradl-rg'
    CapacityName               = 'scbradlfabric20'
    CapacitySize               = 'F128'
    Dataset                    = 'TPCH'
    DataSize                   = 'GB_001'
    ThreadCount                = '1'
    IterationCount             = '1'
    QueryDirectory             = 'C:\Test\Queries'
    OutputDirectory            = 'C:\Test\Output'
    
    CapacityMetricsWorkspace          = ''
    CapacityMetricsSemanticModelName  = ''
    
    CollectQueryInsights                     = $false
    CollectCapacityMetrics                   = $false
    PauseOnCapacitySkuChange                 = $false
    BatchTimeoutInMinutes                    = 120
    QueryRetryLimit                          = 1
    WaitTimeInMinutesForQueryInsightsData    = 15
    WaitTimeInMinutesForCapacityMetricsData  = 15
    WaitTimeInSecondsAfterCapacitySkuChange  = 300
    WaitTimeInSecondsAfterCapacityResume     = 60
}


Invoke-FabricBenchmark @Parameters