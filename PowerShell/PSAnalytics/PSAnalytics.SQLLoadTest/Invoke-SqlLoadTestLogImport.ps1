function Invoke-SqlLoadTestLogImport {
    param (
        [Parameter(Mandatory=$true)]  [string]$LogDirectory,
        [Parameter(Mandatory=$true)]  [string]$Server,
        [Parameter(Mandatory=$true)]  [string]$Database,
        [Parameter(Mandatory=$false)] [string]$ArchiveDirectory
    )

    # If the log directory does not exist, then stop processing.
    if ($false -eq (Test-Path -Path $LogDirectory)) {
        Write-Host "The directory does not exist." -ForegroundColor Red
        Exit
    }

    # If specified, create the archive directory and set the variables to archive after load. 
    $Archive = $false
    $LogFound = $false

    # Create the archive directory if it does not exist. 
    if($ArchiveDirectory -ne "") {
        try {
            if(!(Test-Path $ArchiveDirectory)){
                $null = New-Item -Path $ArchiveDirectory -ItemType "directory"
            }
            $Archive = $true
        }
        catch {
            Write-Host "There was an error creating the archive directory. Files will not be archived." -ForegroundColor Red
            Write-Host ""
            Write-Host ("{0}" -f $_.Exception) -ForegroundColor Red
        }      
    }

    # Populate the directory list variable depending on if a parent or log directory was provided.
    if (Get-ChildItem -Path $LogDirectory -Directory) {
        $LogDirectoryList = Get-ChildItem -Path $LogDirectory -Directory -Exclude $(if ($ArchiveDirectory -ne "") {Split-Path $ArchiveDirectory -Leaf} else {""})
    } else {
        $LogDirectoryList = Get-Item -Path $LogDirectory
    }

    # Loop over the list of directories and process the logs for each.
    foreach ($CurrentLog in $LogDirectoryList) { 
        Write-Host ""
        Write-Host ("Log directory: {0}" -f $CurrentLog.FullName)
        if ($ArchiveDirectory -ne "") {
            Write-Host ("Archive directory: {0}" -f $ArchiveDirectory)
        }
        Write-Host ("Log data processing has started.")
        
        # Define the variables holding the individual log types.
        $LogPath =              Join-Path -Path $CurrentLog.FullName -ChildPath "00_Log.txt"
        $BatchLogPath =         Join-Path -Path $CurrentLog.FullName -ChildPath "01_Batch.txt"
        $ThreadLogPath =        Join-Path -Path $CurrentLog.FullName -ChildPath "02_Thread.txt"
        $IterationLogPath =     Join-Path -Path $CurrentLog.FullName -ChildPath "03_Iteration.txt"
        $QueryLogPath =         Join-Path -Path $CurrentLog.FullName -ChildPath "04_Query.txt"
        $QueryErrorPath =       Join-Path -Path $CurrentLog.FullName -ChildPath "04_QueryError.txt"
        $StatementLogPath =     Join-Path -Path $CurrentLog.FullName -ChildPath "05_Statement.txt"
        $QueryInsightsPath =    Join-Path -Path $CurrentLog.FullName -ChildPath "06_QueryInsights.txt"
        $CapacityMetricsPath =  Join-Path -Path $CurrentLog.FullName -ChildPath "07_CapacityMetrics.txt"

        # Create the datatable to store the log data which will later be written in a single batch to the SQL Server table.
        $LogImport = [System.Data.DataTable]::new()
        [void]$LogImport.Columns.Add("LogType", [string])
        [void]$LogImport.Columns.Add("LogContent", [string])

        # Log Directory
        [void]$LogImport.Rows.Add("LogDirectory", ('{{"LogDirectory" : "{0}"}}' -f (Split-Path $CurrentLog.FullName -Leaf) | ConvertFrom-Json | ConvertTo-Json));
   
        # Log
        if (Test-Path -Path $LogPath) {
            Get-Content -Path $LogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
                foreach ($Log in $_.Keys) {
                    [void]$LogImport.Rows.Add("Log", ($_.$Log | ConvertTo-Json));
                }
            }
            Write-Host ("Log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Log not found at {0}" -f $LogPath) -ForegroundColor Red
        }

        # Batch Log
        if (Test-Path -Path $BatchLogPath) {
            Get-Content -Path $BatchLogPath -Raw | ConvertFrom-JSON | ForEach-Object {    
                foreach ($Log in $_) { 
                    [void]$LogImport.Rows.Add("Batch", ($Log | ConvertTo-Json));
                }
            }
            Write-Host ("Batch log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Batch log not found at {0}" -f $BatchLogPath) -ForegroundColor Red
        }

        # Thread Log
        if (Test-Path -Path $ThreadLogPath) {
            Get-Content -Path $ThreadLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
                foreach ($Log in $_.Keys) {
                    [void]$LogImport.Rows.Add("Thread", ($_.$Log | ConvertTo-Json));
                }
            }
            Write-Host ("Thread log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Thread log not found at {0}" -f $ThreadLogPath) -ForegroundColor Red
        }
        
        # Iteration Log
        if (Test-Path -Path $IterationLogPath) {
            Get-Content -Path $IterationLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
                foreach ($Log in $_.Keys) {
                    [void]$LogImport.Rows.Add("Iteration", ($_.$Log | ConvertTo-Json));
                }
            }
            Write-Host ("Iteration log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Iteration log not found at {0}" -f $IterationLogPath) -ForegroundColor Red
        }
        
        # Query Log
        if (Test-Path -Path $QueryLogPath) {
            Get-Content -Path $QueryLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
                foreach ($Log in $_.Keys) {
                    [void]$LogImport.Rows.Add("Query", ($_.$Log | ConvertTo-Json));
                }
            }
            Write-Host ("Query log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Query log not found at {0}" -f $QueryLogPath) -ForegroundColor Red
        }
        
        # Statement Log
        if (Test-Path -Path $StatementLogPath) {
            Get-Content -Path $StatementLogPath -Raw | ConvertFrom-JSON -AsHashtable | ForEach-Object {
                foreach ($Log in $_.Keys) {
                    [void]$LogImport.Rows.Add("Statement", ($_.$Log | ConvertTo-Json));
                }
            }
            Write-Host ("Statement log import has completed.")
            $LogFound = $true
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
            Write-Host ("Query insights log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Query insights log not found at {0}" -f $QueryInsightsPath) -ForegroundColor Red
        }
        
        # Capacity Metrics
        if (Test-Path -Path $CapacityMetricsPath) {
            Get-Content -Path $CapacityMetricsPath -Raw | ConvertFrom-JSON | ForEach-Object {    
                foreach ($Log in $_) { 
                    [void]$LogImport.Rows.Add("CapacityMetrics", ($Log | ConvertTo-Json));
                }
            }
            Write-Host ("Capacity metrics log import has completed.")
            $LogFound = $true
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
            Write-Host ("Query error log import has completed.")
            $LogFound = $true
        }
        else {
            Write-Host ("Query error log not found at {0}" -f $QueryErrorPath) -ForegroundColor Red
        }

        # Load the data to the SQL database if at least one log was found.
        if ($LogFound) {
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
                Write-Host "An error occurred while clearing the log import table."
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
                Write-Host "Log data imported successfully."
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
                    Write-Host "Log data processed successfully."
                }
            }

            if ($true -eq $Archive) {
                if (Test-Path $ArchiveDirectory) {
                    Move-Item -Path $CurrentLog.FullName -Destination $ArchiveDirectory
                    Write-Host "Log data archived successfully."
                }
            }

            Write-Host ("Log data processing has completed.")
        }
    }
}