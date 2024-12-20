function Invoke-FabricBenchmarkLogImport {
    param (
        [Parameter(Mandatory=$true)]  [string]$LogDirectory,
        [Parameter(Mandatory=$true)]  [string]$Server,
        [Parameter(Mandatory=$true)]  [string]$Database
    )
    
    # Define the variables
    $BatchLogPath =  Join-Path -Path $LogDirectory -ChildPath "01_BatchLog.txt"
    $ThreadLogPath =  Join-Path -Path $LogDirectory -ChildPath "02_ThreadLog.txt"
    $IterationLogPath =  Join-Path -Path $LogDirectory -ChildPath "03_IterationLog.txt"
    $QueryLogPath =  Join-Path -Path $LogDirectory -ChildPath "04_QueryLog.txt"
    $StatementLogPath =  Join-Path -Path $LogDirectory -ChildPath "05_StatementLog.txt"
    $QueryInsightsPath =  Join-Path -Path $LogDirectory -ChildPath "06_QueryInsights.txt"
    $CapacityMetricsPath =  Join-Path -Path $LogDirectory -ChildPath "07_CapacityMetrics.txt"
    $QueryErrorPath =  Join-Path -Path $LogDirectory -ChildPath "QueryError.txt"
    
    $LogImport = [System.Data.DataTable]::new()
    [void]$LogImport.Columns.Add("LogType", [string])
    [void]$LogImport.Columns.Add("LogContent", [string])
    
    # Batch Log
    if (Test-Path -Path $BatchLogPath) {
        Get-Content -Path $BatchLogPath -Raw | ConvertFrom-JSON | ForEach-Object {    
            foreach ($Log in $_) { 
                [void]$LogImport.Rows.Add("BatchLog", ($Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Batch log not found at {0}" -f $BatchLogPath) -ForegroundColor Red
    }
    
    # Thread Log
    if (Test-Path -Path $ThreadLogPath) {
        Get-Content -Path $ThreadLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
            foreach ($Log in $_.Keys) {
                [void]$LogImport.Rows.Add("ThreadLog", ($_.$Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Thread log not found at {0}" -f $ThreadLogPath) -ForegroundColor Red
    }
    
    # Iteration Log
    if (Test-Path -Path $IterationLogPath) {
        Get-Content -Path $IterationLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
            foreach ($Log in $_.Keys) {
                [void]$LogImport.Rows.Add("IterationLog", ($_.$Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Iteration log not found at {0}" -f $IterationLogPath) -ForegroundColor Red
    }
    
    # Query Log
    if (Test-Path -Path $QueryLogPath) {
        Get-Content -Path $QueryLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
            foreach ($Log in $_.Keys) {
                [void]$LogImport.Rows.Add("QueryLog", ($_.$Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Query log not found at {0}" -f $QueryLogPath) -ForegroundColor Red
    }
    
    # Statement Log
    if (Test-Path -Path $StatementLogPath) {
        Get-Content -Path $StatementLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
            foreach ($Log in $_.Keys) {
                [void]$LogImport.Rows.Add("StatementLog", ($_.$Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Statement log not found at {0}" -f $StatementLogPath) -ForegroundColor Red
    }
    
    # Query Insights
    if (Test-Path -Path $QueryInsightsPath) {
        Get-Content -Path $QueryInsightsPath -Raw | ConvertFrom-JSON | ForEach-Object {    
            foreach ($Log in $_) { 
                [void]$LogImport.Rows.Add("QueryInsights", ($Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Query insights not found at {0}" -f $QueryInsightsPath) -ForegroundColor Red
    }
    
    # Capacity Metrics
    if (Test-Path -Path $CapacityMetricsPath) {
        Get-Content -Path $CapacityMetricsPath -Raw | ConvertFrom-JSON | ForEach-Object {    
            foreach ($Log in $_) { 
                [void]$LogImport.Rows.Add("CapacityMetrics", ($Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Capacity Metrics not found at {0}" -f $CapacityMetricsPath) -ForegroundColor Red
    }

    # Query Error
    if (Test-Path -Path $QueryErrorPath) {
        Get-Content -Path $QueryErrorPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
            foreach ($Log in $_.Keys) {
                [void]$LogImport.Rows.Add("QueryError", ($_.$Log | ConvertTo-Json));
            }
        }
    }
    else {
        Write-Host ("Query error log not found at {0}" -f $QueryErrorPath) -ForegroundColor Red
    }
    
    # Load the data to the SQL database.
    $QueryOutput = $null
    $ClearLogImportSuccessful = $false
    $QueryOutput = Invoke-FabricSqlCommand -Server $Server -Database $Database -Query "
    DROP TABLE IF EXISTS dbo.LogImport;
    
    CREATE TABLE dbo.LogImport (
        LogType      [VARCHAR](25),
        LogContent   [JSON]
    )"
    
    # Check the query output for errors. 
    if ($QueryOutput.Errors.Count -gt 0) {
        Write-Host "An error was found when parsing the query error output." -ForegroundColor Red
    
        # Combine the messages and errors into a single output for logging.
        $FullOutput = @()
        ForEach ($line in $($QueryOutput.Messages -split "`r`n")) {
            $FullOutput += $Line + "`r`n"
        }
        ForEach ($line in $($QueryOutput.Errors -split "`r`n")) {
            $FullOutput += $Line + "`r`n"
        }
    
        throw ($FullOutput)
    }
    else {
        $ClearLogImportSuccessful = $true
        Write-Host "Log import table cleared successfully." -ForegroundColor Green
    }
    
    if ($true -eq $ClearLogImportSuccessful) {
        try {
            $ConnectionStringBuilder = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder
            $ConnectionStringBuilder["Server"] = $Server
            $ConnectionStringBuilder["Database"] = $Database
            $ConnectionStringBuilder["Connection Timeout"] = 60
            $ConnectionString = $ConnectionStringBuilder.ToString()
            
            $Connection = New-Object System.Data.SqlClient.SQLConnection($ConnectionString)
            $Connection.ConnectionString = $ConnectionString
            $Connection.AccessToken = Get-FabricAccessToken "SQL"
            $Connection.Open()
            
            $BulkCopy = New-Object -TypeName System.Data.SqlClient.SqlBulkCopy $Connection
            $BulkCopy.DestinationTableName = "dbo.LogImport"
            $BulkCopy.WriteToServer($LogImport)
        }
        catch {
            throw($_.Exception)
        }
    
        $LogImportSuccessful = $true
        Write-Host "Log data imported successfully." -ForegroundColor Green
    }
    
    if ($true -eq $LogImportSuccessful) {
        $QueryOutput = $null
        
        # Process the log data
        $QueryOutput = Invoke-FabricSqlCommand -Server $Server -Database $Database -Query "
        /* Batch */
        INSERT INTO dbo.Batch
        SELECT
            JSON_VALUE(LogContent, '$.ScenarioID') AS ScenarioID,
            JSON_VALUE(LogContent, '$.ScenarioName') AS ScenarioName,
            JSON_VALUE(LogContent, '$.BatchID') AS BatchID,
            JSON_VALUE(LogContent, '$.BatchName') AS BatchName,
            JSON_VALUE(LogContent, '$.BatchDescription') AS BatchDescription,
            JSON_VALUE(LogContent, '$.QueryDirectory') AS QueryDirectory,
            JSON_VALUE(LogContent, '$.ThreadCount') AS ThreadCount,
            JSON_VALUE(LogContent, '$.IterationCount') AS IterationCount,
            JSON_VALUE(LogContent, '$.WorkspaceID') AS WorkspaceID,
            JSON_VALUE(LogContent, '$.WorkspaceName') AS WorkspaceName,
            JSON_VALUE(LogContent, '$.ItemID') AS ItemID,
            JSON_VALUE(LogContent, '$.ItemName') AS ItemName,
            JSON_VALUE(LogContent, '$.ItemType') AS ItemType,
            JSON_VALUE(LogContent, '$.Server') AS Server,
            JSON_VALUE(LogContent, '$.CapacityID') AS CapacityID,
            JSON_VALUE(LogContent, '$.CapacityName') AS CapacityName,
            JSON_VALUE(LogContent, '$.CapacitySubscriptionID') AS CapacitySubscriptionID,
            JSON_VALUE(LogContent, '$.CapacityResourceGroupName') AS CapacityResourceGroupName,
            JSON_VALUE(LogContent, '$.CapacitySize') AS CapacitySize,
            JSON_VALUE(LogContent, '$.CapacityCUPricePerHour') AS CapacityCUPricePerHour,
            JSON_VALUE(LogContent, '$.CapacityRegion') AS CapacityRegion,
            JSON_VALUE(LogContent, '$.Dataset') AS Dataset,
            JSON_VALUE(LogContent, '$.DataSize') AS DataSize,
            JSON_VALUE(LogContent, '$.DataStorage') AS DataStorage,
            JSON_VALUE(LogContent, '$.StartTime') AS StartTime,
            JSON_VALUE(LogContent, '$.EndTime') AS EndTime,
            GETDATE() AS CreateTime,
            GETDATE() AS LastUpdateTime
        FROM dbo.LogImport
        WHERE LogType = 'BatchLog'
    
        /* Thread */
        INSERT INTO dbo.Thread
        SELECT
            JSON_VALUE(LogContent,'$.ThreadID') AS ThreadID,
            JSON_VALUE(LogContent,'$.BatchID') AS BatchID,
            JSON_VALUE(LogContent,'$.Thread') AS Thread,
            JSON_VALUE(LogContent,'$.StartTime') AS StartTime,
            JSON_VALUE(LogContent,'$.EndTime') AS EndTime,
            GETDATE() AS CreateTime,
            GETDATE() AS LastUpdateTime
        FROM dbo.LogImport
        WHERE LogType = 'ThreadLog'
    
        /* Iteration */
        INSERT INTO dbo.Iteration
        SELECT
            JSON_VALUE(LogContent,'$.IterationID') AS IterationID,
            JSON_VALUE(LogContent,'$.BatchID') AS BatchID,
            JSON_VALUE(LogContent,'$.ThreadID') AS ThreadID,
            JSON_VALUE(LogContent,'$.Iteration') AS Iteration,
            JSON_VALUE(LogContent,'$.StartTime') AS StartTime,
            JSON_VALUE(LogContent,'$.EndTime') AS EndTime,
            GETDATE() AS CreateTime,
            GETDATE() AS LastUpdateTime
        FROM dbo.LogImport
        WHERE LogType = 'IterationLog'
    
        /* Query */
        INSERT INTO dbo.Query
        SELECT
            JSON_VALUE(LogContent,'$.QueryID') AS QueryID,
            JSON_VALUE(LogContent,'$.BatchID') AS BatchID,
            JSON_VALUE(LogContent,'$.ThreadID') AS ThreadID,
            JSON_VALUE(LogContent,'$.IterationID') AS IterationID,
            JSON_VALUE(LogContent,'$.Sequence') AS QuerySequence,
            JSON_VALUE(LogContent,'$.QueryFilePath') AS QueryFilePath,
            JSON_VALUE(LogContent,'$.QueryFileName') AS QueryFileName,
            JSON_VALUE(LogContent,'$.Status') AS Status,
            JSON_VALUE(LogContent,'$.StartTime') AS StartTime,
            JSON_VALUE(LogContent,'$.EndTime') AS EndTime,
            JSON_VALUE(LogContent,'$.DistributedStatementCount') AS DistributedStatementCount,
            JSON_VALUE(LogContent,'$.RetryCount') AS RetryCount,
            JSON_VALUE(LogContent,'$.RetryLimit') AS RetryLimit,
            JSON_VALUE(LogContent,'$.ResultsRecordCount') AS ResultsRecordCount,
            JSON_VALUE(LogContent,'$.Errors') AS Errors,
            JSON_VALUE(LogContent,'$.Command') AS Command,
            COALESCE(CONVERT(NVARCHAR(MAX), JSON_QUERY(LogContent,'$.QueryMessage')), JSON_VALUE(LogContent,'$.QueryMessage')) AS QueryMessage,
            GETDATE() AS CreateTime,
            GETDATE() AS LastUpdateTime
        FROM dbo.LogImport
        WHERE LogType = 'QueryLog'
    
        /* Statement */
        DECLARE @CUPricePerHour DECIMAL(18,6) = (
            SELECT TOP 1
                CapacityCUPricePerHour
            FROM dbo.Batch
            WHERE BatchID = (SELECT TOP 1 JSON_VALUE(LogContent,'$.BatchID') AS BatchID FROM dbo.LogImport WHERE LogType = 'StatementLog')
        )
    
        ;WITH StatementLog AS (
            SELECT
                JSON_VALUE(LogContent,'$.StatementID') AS StatementID,
                JSON_VALUE(LogContent,'$.BatchID') AS BatchID,
                JSON_VALUE(LogContent,'$.ThreadID') AS ThreadID,
                JSON_VALUE(LogContent,'$.IterationID') AS IterationID,
                JSON_VALUE(LogContent,'$.QueryID') AS QueryID,
                JSON_VALUE(LogContent,'$.StatementMessage') AS StatementMessage,
                JSON_VALUE(LogContent,'$.DistributedStatementID') AS DistributedStatementID,
                JSON_VALUE(LogContent,'$.DistributedRequestID') AS DistributedRequestID,
                JSON_VALUE(LogContent,'$.QueryHash') AS QueryHash
            FROM dbo.LogImport
            WHERE LogType = 'StatementLog'
        ),
        QueryInsights AS (
            SELECT
                JSON_VALUE(LogContent,'$.DistributedStatementID') AS StatementID,
                JSON_VALUE(LogContent,'$.SessionID') AS QueryInsightsSessionID,
                JSON_VALUE(LogContent,'$.LoginName') AS QueryInsightsLoginName,
                JSON_VALUE(LogContent,'$.SubmitTime') AS QueryInsightsSubmitTime,
                JSON_VALUE(LogContent,'$.StartTime') AS QueryInsightsStartTime,
                JSON_VALUE(LogContent,'$.EndTime') AS QueryInsightsEndTime,
                JSON_VALUE(LogContent,'$.DurationInMS') AS QueryInsightsDurationInMS,
                JSON_VALUE(LogContent,'$.AllocatedCPUTimeMS') AS QueryInsightsAllocatedCPUTimeMS,
                JSON_VALUE(LogContent,'$.DataScannedRemoteStorageMB') AS QueryInsightsDataScannedRemoteStorageMB,
                JSON_VALUE(LogContent,'$.DataScannedMemoryMB') AS QueryInsightsDataScannedMemoryMB,
                JSON_VALUE(LogContent,'$.DataScannedDiskMB') AS QueryInsightsDataScannedDiskMB,
                JSON_VALUE(LogContent,'$.RowCount') AS QueryInsightsRowCount,
                JSON_VALUE(LogContent,'$.Status') AS QueryInsightsStatus,
                JSON_VALUE(LogContent,'$.ResultCacheHit') AS QueryInsightsResultCacheHit,
                JSON_VALUE(LogContent,'$.Label') AS QueryInsightsLabel,
                JSON_VALUE(LogContent,'$.Command') AS QueryInsightsCommand
            FROM dbo.LogImport
            WHERE LogType = 'QueryInsights'
        ),
        CapacityMetrics AS (
            SELECT
                JSON_VALUE(LogContent,'$.OperationID') AS StatementID,
                JSON_VALUE(LogContent,'$.StartTime') AS CapacityMetricsStartTime,
                JSON_VALUE(LogContent,'$.EndTime') AS CapacityMetricsEndTime,
                JSON_VALUE(LogContent,'$.SumCUs') AS CapacityMetricsCUs,
                JSON_VALUE(LogContent,'$.SumDuration') AS CapacityMetricsDurationInSeconds
            FROM dbo.LogImport
            WHERE LogType = 'CapacityMetrics'
        )
    
        INSERT INTO dbo.Statement
        SELECT
            SL.StatementID,
            SL.BatchID,
            SL.ThreadID,
            SL.IterationID,
            SL.QueryID,
            SL.StatementMessage,
            SL.DistributedStatementID,
            SL.DistributedRequestID,
            SL.QueryHash,
            QI.QueryInsightsSessionID,
            QI.QueryInsightsLoginName,
            QI.QueryInsightsSubmitTime,
            QI.QueryInsightsStartTime,
            QI.QueryInsightsEndTime,
            QI.QueryInsightsDurationInMS,
            QI.QueryInsightsAllocatedCPUTimeMS,
            QI.QueryInsightsDataScannedRemoteStorageMB,
            QI.QueryInsightsDataScannedMemoryMB,
            QI.QueryInsightsDataScannedDiskMB,
            QI.QueryInsightsRowCount,
            QI.QueryInsightsStatus,
            QI.QueryInsightsResultCacheHit,
            QI.QueryInsightsLabel,
            QI.QueryInsightsCommand,
            CM.CapacityMetricsStartTime,
            CM.CapacityMetricsEndTime,
            CM.CapacityMetricsCUs,
            CONVERT(DECIMAL(18,6), ROUND(CM.CapacityMetricsCUs * @CUPricePerHour, 6)) AS CapacityMetricsQueryPrice,
            CONVERT(INT, ROUND(CM.CapacityMetricsDurationInSeconds, 0)) AS CapacityMetricsDurationInSeconds,
            GETDATE() AS CreateTime,
            GETDATE() AS LastUpdateTime
        FROM StatementLog AS SL
        LEFT JOIN QueryInsights AS QI
            ON SL.StatementID = QI.StatementID
        LEFT JOIN CapacityMetrics AS CM
            ON SL.StatementID = CM.StatementID

        /* Query Error */
        INSERT INTO dbo.QueryError
        SELECT
            JSON_VALUE(LogContent,'$.QueryID') AS QueryID,
            JSON_VALUE(LogContent,'$.Error') AS Error,
            GETDATE() AS CreateTime,
            GETDATE() AS LastUpdateTime
        FROM dbo.LogImport
        WHERE LogType = 'QueryError'
        "
    
        # Check the query output for errors. 
        if ($QueryOutput.Errors.Count -gt 0) {
            Write-Host "An error was found when parsing the query error output." -ForegroundColor Red
    
            # Combine the messages and errors into a single output for logging.
            $FullOutput = @()
            ForEach ($line in $($QueryOutput.Messages -split "`r`n")) {
                $FullOutput += $Line + "`r`n"
            }
            ForEach ($line in $($QueryOutput.Errors -split "`r`n")) {
                $FullOutput += $Line + "`r`n"
            }
    
            throw ($FullOutput)
        }
        else {
            Write-Host "Log data processed successfully." -ForegroundColor Green
        }
    }
}