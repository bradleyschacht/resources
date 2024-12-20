function Invoke-FabricBenchmarkLogImport {
    param (
        [Parameter(Mandatory=$true)]  [string]$LogDirectory,
        [Parameter(Mandatory=$true)]  [string]$Server,
        [Parameter(Mandatory=$true)]  [string]$Database
    )
    
    # Define the variables
    $BatchLogPath =  Join-Path -Path $LogDirectory -ChildPath "01_Batch.txt"
    $ThreadLogPath =  Join-Path -Path $LogDirectory -ChildPath "02_Thread.txt"
    $IterationLogPath =  Join-Path -Path $LogDirectory -ChildPath "03_Iteration.txt"
    $QueryLogPath =  Join-Path -Path $LogDirectory -ChildPath "04_Query.txt"
    $StatementLogPath =  Join-Path -Path $LogDirectory -ChildPath "05_Statement.txt"
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
        $QueryOutput = Invoke-FabricSqlCommand -Server $Server -Database $Database -Query "EXEC dbo.ProcessLogImportData"
    
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