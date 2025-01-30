$ScenarioID = (New-Guid).ToString()

$Parameters = @{
    ScenarioID                 = $ScenarioID
    ScenarioName               = ''
    BatchName                  = ''
    BatchDescription           = ''
    WorkspaceName              = ''
    ItemName                   = ''
    CapacitySubscriptionID     = ''
    CapacityResourceGroupName  = ''
    CapacityName               = ''
    CapacitySize               = ''
    Dataset                    = ''
    DataSize                   = ''
    DataStorage                = ''
    <# DatabaseIsVOrderEnabled   = $true #>
    ThreadCount                = 1
    IterationCount             = 1
    QueryDirectory             = ''
    LogDirectory               = 'C:\SQLLoadTest'

    CapacityMetricsWorkspace          = ''
    CapacityMetricsSemanticModelName  = 'Fabric Capacity Metrics'
    
    CollectQueryInsights                     = $true
    CollectCapacityMetrics                   = $true
    PauseOnCapacitySkuChange                 = $false
    StoreQueryResults                        = $false
    BatchTimeoutInMinutes                    = 120
    QueryRetryLimit                          = 0
    WaitTimeInMinutesAfterCapacityResume     = 1
    WaitTimeInMinutesAfterCapacitySkuChange  = 5
    WaitTimeInMinutesForQueryInsightsData    = 15
    WaitTimeInMinutesForCapacityMetricsData  = 15
}

Invoke-SqlLoadTest @Parameters