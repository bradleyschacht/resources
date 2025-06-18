# Easy Mode
$Parameters = @{
    QueryDirectory      = ''
    LogDirectory        = ''

    ScenarioID          = ((New-Guid).ToString())
    ScenarioName        = ''
    BatchName           = ''
    BatchDescription    = ''
    Server              = ''
    ItemName            = ''
    ThreadCount         = 1
    IterationCount      = 1
}

Invoke-SqlLoadTest @Parameters

# Advanced Mode
$Parameters = @{
    Platform                                = 'Fabric'
    QueryDirectory                          = ''
    LogDirectory                            = ''

    ScenarioID                              = ((New-Guid).ToString())
    ScenarioName                            = ''
    BatchName                               = ''
    BatchDescription                        = ''
    Dataset                                 = ''
    DataSize                                = ''
    DataStorage                             = ''
    ThreadCount                             = 1
    IterationCount                          = 1
    StoreQueryResults                       = $false
    BatchTimeoutInMinutes                   = 120
    QueryRetryLimit                         = 0

    WorkspaceName                           = ''
    Server                                  = ''
    ItemName                                = ''
    ItemType                                = ''
    CapacitySubscriptionID                  = ''
    CapacityResourceGroupName               = ''
    CapacityName                            = ''
    CapacitySize                            = ''
    CapacityMetricsWorkspace                = 'Fabric Capacity Metrics'
    CapacityMetricsSemanticModelName        = 'Fabric Capacity Metrics'
    CollectQueryInsights                    = $false
    CollectCapacityMetrics                  = $false
    PauseOnCapacitySkuChange                = $false
    WaitTimeInMinutesAfterCapacityResume    = 1
    WaitTimeInMinutesAfterCapacitySkuChange = 5
    WaitTimeInMinutesForQueryInsightsData   = 20
    WaitTimeInMinutesForCapacityMetricsData = 20

    # Use at your own risk
    AdvancedMode                            = $true
    DebugMode                               = $false
}

Invoke-SqlLoadTest @Parameters