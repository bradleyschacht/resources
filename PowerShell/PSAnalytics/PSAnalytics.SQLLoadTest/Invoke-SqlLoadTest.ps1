function Invoke-SqlLoadTest {
    param (
        # Optional Scenario Details
        [Parameter(Mandatory=$false)] [string]$ScenarioID,
        [Parameter(Mandatory=$false)] [string]$ScenarioName,

        # Batch Details
        [Parameter(Mandatory=$true)]  [string]$BatchName,
        [Parameter(Mandatory=$false)] [string]$BatchDescription,
        [Parameter(Mandatory=$true)]  [string]$WorkspaceName,
        [Parameter(Mandatory=$true)]  [string]$ItemName,
        [Parameter(Mandatory=$true)]  [string]$CapacitySubscriptionID,
        [Parameter(Mandatory=$true)]  [string]$CapacityResourceGroupName,
        [Parameter(Mandatory=$true)]  [string]$CapacityName,
        [Parameter(Mandatory=$true)]  [string]$CapacitySize,
        [Parameter(Mandatory=$true)]  [string]$Dataset,
        [Parameter(Mandatory=$true)]  [string]$DataSize,
        [Parameter(Mandatory=$true)]  [string]$DataStorage,
        [Parameter(Mandatory=$false)] [boolean]$DatabaseIsVOrderEnabled,
        [Parameter(Mandatory=$true)]  [int32]$ThreadCount,
        [Parameter(Mandatory=$true)]  [int32]$IterationCount,
        [Parameter(Mandatory=$true)]  [string]$QueryDirectory,
        [Parameter(Mandatory=$true)]  [string]$LogDirectory,

        # Capacity Metrics
        [Parameter(Mandatory=$false)] [string]$CapacityMetricsWorkspace,
        [Parameter(Mandatory=$false)] [string]$CapacityMetricsSemanticModelName,

        # Runtime Variables
        [Parameter(Mandatory=$false)] [boolean]$CollectQueryInsights                    = $true,    <#  Default: $true  #>
        [Parameter(Mandatory=$false)] [boolean]$CollectCapacityMetrics                  = $true,    <#  Default: $true  #>
        [Parameter(Mandatory=$false)] [boolean]$PauseOnCapacitySkuChange                = $false,   <#  Default: $false  #>
        [Parameter(Mandatory=$false)] [boolean]$StoreQueryResults                       = $false,   <#  Default: $false  #>
        [Parameter(Mandatory=$false)] [int32]$BatchTimeoutInMinutes                     = 120,      <#  Default: 120 minutes  #>
        [Parameter(Mandatory=$false)] [int32]$QueryRetryLimit                           = 0,        <#  Default: 0 -> The query will not retry on failure.  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInMinutesForQueryInsightsData     = 15,       <#  Default: 15  minutes  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInMinutesForCapacityMetricsData   = 15,       <#  Default: 15  minutes  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInSecondsAfterCapacitySkuChange   = 300,      <#  Default: 5 minutes -> 300 seconds  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInSecondsAfterCapacityResume      = 60        <#  Default: 1 minute  -> 60  seconds  #>
    )

    # Job Initialization Script
    $JobInitializationScript = {
        
        function Add-LogEntry {
            param (
                $Thread,
                $Iteration,
                $Query,
                $MessageType,
                $MessageText
            )

            # Generate a key for the log record.
            $LogKey = (New-Guid).ToString()
            $MessageTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss.ffff")
            
            # Build the message hashtable.
            $Message = @{
                "Thread"          = $Thread
                "Iteration"       = $Iteration
                "Query"           = $Query
                "MessageType"     = $MessageType
                "MessageTime"     = $MessageTime
                "MessageText"     = $MessageText
            }

            # Get the list of empty keys.
            $EmptyKeys = $Message.Keys | Where-Object { $null -eq $Message[$_]}

            # Remove the empty keys from the hashtable.
            foreach ($Key in $EmptyKeys) {
                $Message.Remove($Key)
            }

            # Add the message to the log or update existing records.
            $LocalLog[$LogKey] = $Message

            # Write the message to the console.
            if($MessageType -in ("Error", "Warning")) {
                Write-Host ("{0} | {1} | Thread {2} | Iteration {3} | Query {4} | {5}" -f $MessageTime, $MessageType, $Thread, $Iteration, $Query, $MessageText) -ForegroundColor Red
            }
            else {
                Write-Host ("{0} | {1} | Thread {2} | Iteration {3} | Query {4} | {5}" -f $MessageTime, $MessageType, $Thread, $Iteration, $Query, $MessageText)
            }

            <#
                Notes for later: Enable the real time write to a log file locally.
                
                # Write the message to the log.
                Write-Output ($Message | ConvertTo-JSON | Out-String) | Out-File $LogFilePath -Append
            #>
        }
    }

    # Load all the functions.
    Invoke-Expression ($JobInitializationScript | Out-String)

    # Check to be sure the proper Capacity Metrics parameter combination was passed.
    if ($true -eq $CollectCapacityMetrics) {
        if (($CapacityMetricsWorkspace -ne "" -and $null -ne $CapacityMetricsWorkspace) -and ($CapacityMetricsSemanticModelName -ne "" -and $null -ne $CapacityMetricsSemanticModelName)) {
            # Continue running the script.
        }
        else {
            Write-Host "No value was provided for the Capacity Metrics parameters." -ForegroundColor Red
            Write-Host "When `$CollectCapacityMetrics is set to `$true a value must be provided for the CapacityMetricsWorkspace and CapacityMetricsSemanticModelName parameters. The batch will not be run." -ForegroundColor Red
            Exit
        }
    }

    # Create the synchronized hashtable to store the logs and thread status.
    $ThreadStatus = [Hashtable]::Synchronized(@{})
    $Log = [Hashtable]::Synchronized(@{})
    $LogBatch = [Hashtable]::@{}
    $LogThread = [Hashtable]::Synchronized(@{})
    $LogIteration = [Hashtable]::Synchronized(@{})
    $LogQuery = [Hashtable]::Synchronized(@{})
    $LogQueryError = [Hashtable]::Synchronized(@{})
    $LogQueryResult = [Hashtable]::Synchronized(@{})
    $LogStatement = [Hashtable]::Synchronized(@{})

    # Create the local log variable reference.
    $LocalLog = $Log

    # Generate a batch id and store the start time.
    $BatchID = (New-Guid).ToString()
    $BatchStartTime = Get-Date

    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Batch {0} has started." -f $BatchName)

    # Call the various Fabric APIs to gather information about the environment. 
    $WorkspaceName                  = $WorkspaceName
    $CapacitySubscriptionID         = $CapacitySubscriptionID
    $CapacityResourceGroupName      = $CapacityResourceGroupName
    $CapacityName                   = $CapacityName
    $CapacitySize                   = $CapacitySize
    $ItemName                       = $ItemName

    # Get the workspace id.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to gather workspace id.")
    $WorkspaceID = (Get-FabricWorkspace -Workspace $WorkspaceName).id

    # Get the capacity id.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to capacity id.")
    $CapacityID = (Get-FabricCapacity -Capacity $CapacityName).id

    # Get the capacity region.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get capacity region.")
    $CapacityRegion = (Get-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName).location

    # Get the CU price per hour for the capacity's region.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get capacity CU price per hour.")
    $CapacityUnitPricePerHour = (Get-FabricCUPricePerHour -Region $CapacityRegion).Items.retailPrice

    # Determine if the item is a lakehouse or a warehouse, then gather the SQL connection string information.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get lakehouse information.")
    $Lakehouse = Get-FabricLakehouse -Workspace $WorkspaceID -Lakehouse $ItemName
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get warehouse information.")
    $Warehouse = (Get-FabricWarehouse -Workspace $WorkspaceID -Warehouse $ItemName)
    if ($null -ne $Lakehouse.id) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("A lakehouse item type has been found.")
        $ItemID     = $Lakehouse.id
        $ItemType   = $Lakehouse.type
        $Server     = $Lakehouse.sqlEndpointProperties.connectionString
    }
    elseif ($null -ne $Warehouse.id) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("A warehouse item type has been found.")
        $ItemID     = $Warehouse.id
        $ItemType   = $Warehouse.type
        $Server     = $Warehouse.connectionString
    }
    else {
        "Unknown item type."
    }

    # If any variables are still empty or $null then don't run the batch.
    if (
        [string]::IsNullOrEmpty($WorkspaceName) -or `
        [string]::IsNullOrEmpty($WorkspaceID) -or `
        [string]::IsNullOrEmpty($ItemID) -or `
        [string]::IsNullOrEmpty($ItemName) -or `
        [string]::IsNullOrEmpty($ItemType) -or `
        [string]::IsNullOrEmpty($Server) -or `
        [string]::IsNullOrEmpty($CapacitySubscriptionID) -or `
        [string]::IsNullOrEmpty($CapacityResourceGroupName) -or `
        [string]::IsNullOrEmpty($CapacityName) -or `
        [string]::IsNullOrEmpty($CapacitySize) -or `
        [string]::IsNullOrEmpty($CapacityRegion) -or `
        [string]::IsNullOrEmpty($CapacityUnitPricePerHour) -or `
        [string]::IsNullOrEmpty($CapacityID)
    ) {
        $RunBatch = $false
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("At least one batch lookup value was not found. The batch will be terminated.")
    }
    else {
        $RunBatch = $true
    }

    # Write the parameters to the console and the log.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Workspace: {0}" -f $WorkspaceName)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("WorkspaceID: {0}" -f $WorkspaceID)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("ItemID: {0}" -f $ItemID)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("ItemName: {0}" -f $ItemName)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("ItemType: {0}" -f $ItemType)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Server: {0}" -f $Server)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacitySubscriptionID: {0}" -f $CapacitySubscriptionID)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityResourceGroupName: {0}" -f $CapacityResourceGroupName)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityName: {0}" -f $CapacityName)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacitySize: {0}" -f $CapacitySize)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityRegion: {0}" -f $CapacityRegion)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityUnitPricePerHour: {0}" -f $CapacityUnitPricePerHour)
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityID: {0}" -f $CapacityID)

    # Perform the necessary capacity related functions (Assign | Scale | Resume) then check to be sure the SQL endpoint is accessible. 
    if ($true -eq $RunBatch) {
        # Assign the correct capacity for this batch to the workspace.
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Assigning capacity to the workspace.")
        $null = Set-FabricWorkspaceCapacity -Workspace $WorkspaceID -Capacity $CapacityID
        
        # Get the capacity's current state and SKU.
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Checking capacity SKU and status.")
        $CapacityCurrent = Get-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName
        
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity current state: {0}" -f $CapacityCurrent.properties.state)
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity current SKU: {0}" -f $CapacityCurrent.sku.name)
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity expected SKU: {0}" -f $CapacitySize)

        # Check if the current vs. expected SKUs match. If they don't, scale the capacity.
        if ($CapacityCurrent.sku.name -ne $CapacitySize) {
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity SKUs do not match.")
            
            # Pause the capacity if it is running so that the current activity is cleared.
            if (($CapacityCurrent.properties.state -ne "Paused") -and ($true -eq $PauseOnCapacitySkuChange)) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Pausing the capacity before scaling.")
                $null = Suspend-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName                
            }

            # Scale the capacity to the proper SKU.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Initiating a scale operation.")
            $CapacityCurrent = Set-FabricAzCapacitySku -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName -Sku $CapacitySize
            
            # Wait for x seconds after a SKU change.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting {0} seconds after a scaling operation." -f $WaitTimeInSecondsAfterCapacitySkuChange)
            Start-Sleep -Seconds $WaitTimeInSecondsAfterCapacitySkuChange
        }

        # Resume the capacity if it is not running.
        if ($CapacityCurrent.properties.state -ne "Active") {
            # Start the capacity.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The capacity is paused. Resuming the capacity.")
            $null = Resume-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName
            
            # Wait for x seconds after the capacity becomes active.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting {0} seconds after a capacity resume operation." -f $WaitTimeInSecondsAfterCapacityResume)
            Start-Sleep -Seconds $WaitTimeInSecondsAfterCapacityResume
        }

        # Set the variables for the SQL endpoint check loop.
        $RetryLimit = 2
        $RetryCount = 0
        $SQLEndpointActive = $false

        do {
            try {
                # Run a query against the database to see if it can connect and return some relevant metadata with it.
                $Query = "SELECT compatibility_level, collation_name, is_auto_create_stats_on, is_auto_update_stats_on, is_result_set_caching_on, is_vorder_enabled FROM sys.databases WHERE name = '{0}'" -f $ItemName
                $QueryOutput = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query $Query

                # Check the query output for errors. 
                if ($QueryOutput.Errors.Count -gt 0) {
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

                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("SQL endpoint is online and responding.")
                $DatabaseCompatibilityLevel      = $QueryOutput.Dataset.Tables.Rows.compatibility_level
                $DatabaseCollationName           = $QueryOutput.Dataset.Tables.Rows.collation_name
                $DatabaseIsAutoCreateStatsOn     = $QueryOutput.Dataset.Tables.Rows.is_auto_create_stats_on
                $DatabaseIsAutoUpdateStatsOn     = $QueryOutput.Dataset.Tables.Rows.is_auto_update_stats_on
                $DatabaseIsVOrderEnabled         = $(if ($null -eq $DatabaseIsVOrderEnabled) {$QueryOutput.Dataset.Tables.Rows.is_vorder_enabled} else {$DatabaseIsVOrderEnabled})
                $DatabaseIsResultSetCachingOn    = $QueryOutput.Dataset.Tables.Rows.is_result_set_caching_on
                
                # Set the varaibles to indicate the batch should be run and the SQL endpoint check loop is complete.
                $RunBatch = $true
                $SQLEndpointActive = $true
            }
            catch {
                # Set the variables to not run the batch if the SQL endpoint check fails and iterate to the next check loop.
                $RunBatch = $false
                $RetryCount = $RetryCount + 1
                
                # If the loop has reached its retry limit, terminate the batch. 
                if ($RetryCount -gt $RetryLimit) {
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1))
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ($_.Exception.Message)
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("SQL endpoint check retry limit has been met. Terminating the SQL endpoint check and the batch.")
                }
                # If the loop has not reached its limit, wait and try again.
                else {
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Warning" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1))
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Warning" -MessageText ($_.Exception.Message)
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Warning" -MessageText ("SQL endpoint check retry limit has not been met. Rechecking the SQL endpoint in 60 seconds.")
                    Start-Sleep -Seconds 60
                }     
            }
        } until (
            # Continue running the loop until the SQL endpoint is active or the retry limit is reached.
            ($true -eq $SQLEndpointActive) -or ($RetryCount -gt $RetryLimit)
        )
    }

    if ($true -eq $RunBatch) {

        $JobFunctions = ("function Get-FabricAccessToken {${function:Get-FabricAccessToken}}").ToString() + "
        " + ("function Invoke-FabricSQLCommand {${function:Invoke-FabricSQLCommand}}").ToString() + "
        " + ("function Find-FabricSQLMessage {${function:Find-FabricSQLMessage}}").ToString()

        $ParallelThreads = foreach ($Thread in 1..$ThreadCount) {
            # Set the job name for the thread.
            $JobName = "Thread_{0}_{1}" -f $Thread, (New-Guid)

            # Start the job.
            Start-ThreadJob `
            -Name $JobName `
            -StreamingHost $Host `
            -InitializationScript $JobInitializationScript `
            -ThrottleLimit $ThreadCount `
            -ArgumentList ($BatchID, $Thread, $ThreadCount, $IterationCount, $Server, $ItemName, $QueryRetryLimit, $QueryDirectory, $StoreQueryResults, $JobFunctions) `
            -ScriptBlock {
                param(
                    $BatchID,
                    $Thread,
                    $ThreadCount,
                    $IterationCount,
                    $Server,
                    $ItemName,
                    $QueryRetryLimit,
                    $QueryDirectory,
                    $StoreQueryResults,
                    $JobFunctions
                )

                # Load the necessary functions.
                $JobFunctions | Invoke-Expression

                # Generate a thread id and store the start time.
                $ThreadID = (New-Guid).ToString()
                $ThreadStartTime = Get-Date

                # Add the message to the log.
                $LocalLogThread[$ThreadID] = @{
                    "ThreadID"      = $ThreadID
                    "BatchID"       = $BatchID
                    "Thread"        = $Thread
                    "StartTime"     = $ThreadStartTime
                }

                # Create the local log variable references for the synchronized hashtables.
                $LocalThreadStatus = $using:ThreadStatus
                $LocalLog = $using:Log
                $LocalLogThread = $using:LogThread
                $LocalLogIteration = $using:LogIteration
                $LocalLogQuery = $using:LogQuery
                $LocalLogQueryError = $using:LogQueryError
                $LocalLogQueryResult = $using:LogQueryResult
                $LocalLogStatement = $using:LogStatement

                Add-LogEntry -Thread $Thread -Iteration $null -MessageType "Information" -MessageText ("Thread {0} of {1} has started." -f $Thread, $ThreadCount)

                # Add a record indicating that the thread has started.
                $LocalThreadStatus[$Thread] = "Started"

                # Wait for all the other threads to start before running anything. 
                do {
                    Start-Sleep -Milliseconds 500
                } while (
                    $LocalThreadStatus.Count -lt $ThreadCount
                )

                Add-LogEntry -Thread $Thread -Iteration $null -MessageType "Information" -MessageText ("Thread {0} of {1} detected all other threads have started." -f $Thread, $ThreadCount)

                foreach ($Iteration in 1..$IterationCount) {
                    # Generate an iteration id and store the start time.
                    $IterationID = (New-Guid).ToString()
                    $IterationStartTime = Get-Date

                    # Add the message to the log.
                    $LocalLogIteration[$IterationID] = @{
                        "IterationID"   = $IterationID
                        "BatchID"       = $BatchID
                        "ThreadID"      = $ThreadID
                        "Iteration"     = $Iteration
                        "StartTime"     = $IterationStartTime
                    }
                    
                    Add-LogEntry -Thread $Thread -Iteration $Iteration -MessageType "Information" -MessageText ("Iteration {0} of {1} has started." -f $Iteration, $IterationCount)
                    
                    # Store the full path for each file containing a query that need to be run.
                    $QueryList = Get-ChildItem -Path $QueryDirectory -File
                    
                    Add-LogEntry -Thread $Thread -Iteration $Iteration -MessageType "Information" -MessageText ("{0} queries(s) will be run in series." -f ($QueryList | Measure-Object | Select-Object -ExpandProperty Count))

                    # Reset the query sequence counter.
                    $QuerySequence = 0
                    
                    # Loop over each query and run them in series.
                    foreach($CurrentQuery in $QueryList) {
                        # Set the variables for the query run loop.
                        $QuerySequence++
                        $ContinueLoop = $true
                        $RetryCount = 0
                        $RetryLimit = $QueryRetryLimit
                        $QueryID = (New-Guid).ToString()
                        
                        <#
                            Notes for later: Consider storing the framework start/end time for the query as well: $QueryStartTime = Get-Date
                        #>

                        # Try to run the query until it completes successfully or until it reaches the retry limit. 
                        do {
                            try {                                
                                # Reset the query output variables.
                                $QueryOutput = $null
                                $QuerySuccessful = $false
                                
                                # Read the file containing the query and store the query text.
                                $Query = Get-Content -Path $CurrentQuery.FullName -Raw
                                
                                # Run the current query and collect the output for parsing.
                                Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Query {0} of {1}" -f $QuerySequence, ($QueryList | Measure-Object | Select-Object -ExpandProperty Count))
                                $QueryOutput = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query $Query

                                # Check the query output for errors. 
                                if ($QueryOutput.Errors.Count -gt 0) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ("An error was found when parsing the query output.")

                                    # Combine the messages and errors into a single output for logging.
                                    $FullOutput = @()
                                    ForEach ($line in $($QueryOutput.Messages -split "`r`n")) {
                                        $FullOutput += $Line + "`r`n"
                                    }
                                    ForEach ($line in $($QueryOutput.Errors -split "`r`n")) {
                                        $FullOutput += $Line + "`r`n"
                                    }
                                    # Clear the procedure output before throwing the error so it doesn't log a record for each retry.
                                    $QueryOutput = @()
                                    throw ($FullOutput)
                                }

                                # If there was no error, stop looping and indicate the query was successful.
                                $ContinueLoop = $false
                                $QuerySuccessful = $true
                                Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Query execution has ended successfully.")
                            }
                            catch {
                                # Generate an error key for the log.
                                $ErrorKey = (New-Guid).ToString()

                                # Add the message to the log.
                                $LocalLogQueryError[$ErrorKey] = @{
                                    "QueryID"    = $QueryID
                                    "Error"      = $_.Exception.Message
                                }

                                # If there was an error and the retry limit has been reached raise an error.
                                if ($RetryCount -ge $RetryLimit) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Error" -MessageText ("Query has encountered an error.")
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Error" -MessageText ($_.Exception.Message)
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Error" -MessageText ("Query retry limit has been met ({0} of {1}). Exiting retry loop and terminating iteration." -f $RetryCount, $RetryLimit)
                                    $ContinueLoop = $false
                                }
                                # If there was an error and the retry limit has not been reached raise a warning then retry the query.
                                else {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ("Query has encountered an error.")
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ($_.Exception.Message)
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ("Query retry limit has not been met ({0} of {1}). Retry loop will attempt to rerun the query in 10 seconds." -f $RetryCount, $RetryLimit)
                                    $RetryCount = $RetryCount + 1
                                    Start-Sleep -Seconds 10
                                }
                            }
                        } while (
                            $true -eq $ContinueLoop
                        )

                        # If the query was successful parse the output for statement ids, custom logs, and query results.
                        if($QuerySuccessful) {
                            # Parse the query messages and create records in the query log for each distributed statement id found.
                            $DistributedStatementCount = 0

                            # For each message in the query output check to see if it contains a distributed statement id for a query that was executed. If it does, log it. There could be multiple distributed statement ids per query executed by the script (for example a stored procedure may run multiple queries).
                            Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has started.")
                            foreach ($Message in $QueryOutput.Messages) {
                                # Parse the message to see if it contains a distributed statement id.
                                $ParsedMessage = Find-FabricSQLMessage -Message $Message

                                # If it does contain a distributed statement id, add it to the statement log. 
                                if ($null -ne $ParsedMessage.StatementID) {
                                    $DistributedStatementCount += 1

                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Iteration {0} of {1} has detected a query statement id. The distributed statement id {2} will be written to the statement log." -f $Iteration.Iteration, $Iteration.IterationCount, $ParsedMessage.StatementID)

                                    # Add the message to the log.
                                    $LocalLogStatement[$ParsedMessage.StatementID] = @{
                                        "StatementID"            = $ParsedMessage.StatementID
                                        "BatchID"                = $BatchID
                                        "ThreadID"               = $ThreadID
                                        "Thread"                 = $Thread
                                        "IterationID"            = $IterationID
                                        "Iteration"              = $Iteration
                                        "QueryID"                = $QueryID
                                        "StatementMessage"       = $ParsedMessage.Message
                                        "DistributedStatementID" = $ParsedMessage.StatementID
                                        "DistributedRequestID"   = $ParsedMessage.DistributedRequestID
                                        "QueryHash"              = $ParsedMessage.QueryHash
                                    }
                                }
                                else {
                                    # Do nothing.
                                }
                            }

                            Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has ended.")

                            if ($QueryOutput.Dataset.Tables.Count -gt 0 -and ($true -eq $StoreQueryResults -or ($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog"))) {
                                if ($true -eq $StoreQueryResults) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName  -MessageType "Information" -MessageText ("The query results will be stored in the query result log.")
                                }

                                if (($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog")) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName  -MessageType "Information" -MessageText ("A custom query log was detected and will be stored in the query result log.")
                                }

                                # Add the message to the log.
                                $LocalLogQueryResult[$QueryID] = @{
                                    "QueryID"   = $QueryID
                                    "Results"   = $(if ($true -eq $StoreQueryResults) {$QueryOutput.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors})
                                    "CustomLog" = $(if (($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog")) {$QueryOutput.Dataset.Tables[-1].Rows.QueryCustomLog})
                                }
                            }
                        }

                        # Add the message to the log.
                        $LocalLogQuery[$QueryID] = @{
                            "QueryID"                   = $QueryID
                            "BatchID"                   = $BatchID
                            "ThreadID"                  = $ThreadID
                            "Thread"                    = $Thread
                            "IterationID"               = $IterationID
                            "Iteration"                 = $Iteration
                            "Sequence"                  = $QuerySequence
                            "QueryFilePath"             = $CurrentQuery.FullName
                            "QueryFileName"             = $CurrentQuery.BaseName
                            "Status"                    = $(if ($false -eq $QuerySuccessful) {"Failure"} elseif ($true -eq $QuerySuccessful -and -$RetryCount -gt 0) {"Success after retry"} elseif ($true -eq $QuerySuccessful -and $RetryCount -eq 0) {"Success"} else {"Unknown Status"})
                            "StartTime"                 = $(if ($true -eq $QuerySuccessful) {"{0}" -f $QueryOutput.QueryStartTime})
                            "EndTime"                   = $(if ($true -eq $QuerySuccessful) {"{0}" -f $QueryOutput.QueryEndTime})
                            "DurationInMS"              = $(if ($true -eq $QuerySuccessful) {[long]($QueryOutput.QueryEndTime - $QueryOutput.QueryStartTime).TotalMilliseconds})
                            "Duration"                  = $(if ($true -eq $QuerySuccessful) {"{0}" -f ($QueryOutput.QueryEndTime - $QueryOutput.QueryStartTime).ToString("hh\:mm\:ss\.ffffff")})
                            "DistributedStatementCount" = $DistributedStatementCount
                            "RetryCount"                = $RetryCount
                            "RetryLimit"                = $RetryLimit
                            "ResultsRecordCount"        = $QueryOutput.Dataset.Tables.Rows.Count
                            "HasError"                  = $(if ($false -eq $QuerySuccessful -or $RetryCount -gt 0) {$true} else {$false})
                            "Command"                   = $Query
                            "QueryMessage"              = $(if ($true -eq $QuerySuccessful) {$QueryOutput.Messages})
                        }
                    }

                    # Update the message in the log.
                    $IterationEndTime = Get-Date
                    $LocalLogIteration[$IterationID] = @{
                        "IterationID"   = $IterationID
                        "BatchID"       = $BatchID
                        "ThreadID"      = $ThreadID
                        "Iteration"     = $Iteration
                        "StartTime"     = $IterationStartTime
                        "EndTime"       = $IterationEndTime
                        "DurationInMS"  = $([long]($IterationEndTime - $IterationStartTime).TotalMilliseconds)
                        "Duration"      = $("{0}" -f ($IterationEndTime - $IterationStartTime).ToString("hh\:mm\:ss\.ffffff"))
                    }
                    Add-LogEntry -Thread $Thread -Iteration $Iteration -MessageType "Information" -MessageText ("Iteration {0} of {1} has ended." -f $Iteration, $IterationCount)
                }

                # Update the message in the log.
                $ThreadEndTime = Get-Date
                $LocalLogThread[$ThreadID] = @{
                    "ThreadID"      = $ThreadID
                    "BatchID"       = $BatchID
                    "Thread"        = $Thread
                    "StartTime"     = $ThreadStartTime
                    "EndTime"       = $ThreadEndTime
                    "DurationInMS"  = $([long]($ThreadEndTime - $ThreadStartTime).TotalMilliseconds)
                    "Duration"      = $("{0}" -f ($ThreadEndTime - $ThreadStartTime).ToString("hh\:mm\:ss\.ffffff"))
                }

                Add-LogEntry -Thread $Thread -Iteration $null -MessageType "Information" -MessageText ("Thread {0} of {1} has ended." -f $Thread, $ThreadCount)
            }
        }

        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting for parallel threads to complete.")

        # Let the threads run for up to X minutes before stopping them.
        $WaitForJobsUntil = (Get-Date).AddMinutes($BatchTimeoutInMinutes)
        $ContinueLoop = $true

        # Code to allow the threads to write to the console while waiting for them to complete and to stop the batch if it exceeds the timeout.
        do {
            if ((Get-Date) -gt $WaitForJobsUntil) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("The batch has reached the timeout limit of {0} minutes." -f $BatchTimeoutInMinutes)
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("{0} of {1} thread(s) are running and will be stopped." -f ((Get-Job -State "Running").count), $ThreadCount)
                
                foreach ($Job in (Get-Job -State "Running")) {
                    $Job | Stop-Job
        
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("The thread {0} has been stopped." -f $job.Name)
        
                    <#
                        Notes for later: Put a script here to go add the end date for all threads that were terminated.
                    #>
                }
            }

            Start-Sleep -Seconds 10
        } while (
            ((Get-Job -State "Running").count -gt 0) -and ($true -eq $ContinueLoop)
        )

        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("All parallel threads have completed.")

        # Clean up all the completed jobs.
        foreach ($Job in (Get-Job -State "Completed")) {
            $Job | Remove-Job
        }

        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("All threads have been cleaned up.")       
        
        $BatchEndTime = Get-Date
        
        $LogBatch = @{
            "ScenarioID"                   = $ScenarioID
            "ScenarioName"                 = $ScenarioName
            "BatchID"                      = $BatchID
            "BatchName"                    = $BatchName
            "BatchDescription"             = $BatchDescription
            "QueryDirectory"               = $QueryDirectory
            "ThreadCount"                  = $ThreadCount
            "IterationCount"               = $IterationCount
            "WorkspaceID"                  = $WorkspaceID
            "WorkspaceName"                = $WorkspaceName
            "ItemID"                       = $ItemID
            "ItemName"                     = $ItemName
            "ItemType"                     = $ItemType
            "Server"                       = $Server
            "DatabaseCompatibilityLevel"   = $DatabaseCompatibilityLevel
            "DatabaseCollation"            = $DatabaseCollationName
            "DatabaseIsAutoCreateStatsOn"  = $DatabaseIsAutoCreateStatsOn
            "DatabaseIsAutoUpdateStatsOn"  = $DatabaseIsAutoUpdateStatsOn
            "DatabaseIsVOrderEnabled"      = $DatabaseIsVOrderEnabled
            "DatabaseIsResultSetCachingOn" = $DatabaseIsResultSetCachingOn
            "CapacityID"                   = $CapacityID
            "CapacityName"                 = $CapacityName
            "CapacitySubscriptionID"       = $CapacitySubscriptionID
            "CapacityResourceGroupName"    = $CapacityResourceGroupName
            "CapacitySize"                 = $CapacitySize
            "CapacityUnitPricePerHour"     = $CapacityUnitPricePerHour
            "CapacityRegion"               = $CapacityRegion
            "Dataset"                      = $Dataset
            "DataSize"                     = $DataSize
            "DataStorage"                  = $DataStorage
            "StartTime"                    = $BatchStartTime
            "EndTime"                      = $BatchEndTime
            "DurationInMS"                 = $([long]($BatchEndTime - $BatchStartTime).TotalMilliseconds)
            "Duration"                     = $("{0}" -f ($BatchEndTime - $BatchStartTime).ToString("hh\:mm\:ss\.ffffff"))
        }
    }

    if (($true -eq $CollectQueryInsights -or $true -eq $CollectCapacityMetrics) -and $true -eq $RunBatch) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from the statement log.")

        # Get the list of distributed statement ids that need to have additional metrics collected from query insights or capacity metrics.
        $DistributedStatementCount = ($LogStatement.Values.DistributedStatementID | Measure-Object | Select-Object -ExpandProperty Count)
        
        
        if ($DistributedStatementCount -gt 0) {
            $DistributedStatementIDListQueryInsights = ("'{0}'" -f ($LogStatement.Values.DistributedStatementID -join "','")).ToUpper()
            $DistributedStatementIDListCapacityMetrics = ($LogStatement.Values.DistributedStatementID).ToUpper()

            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the statement log." -f $DistributedStatementCount)
        }
        else {
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("No distributed statement ids were found in the statement log.")
        }
    }

    # Gather details from query insights. 
    if ($true -eq $CollectQueryInsights -and $true -eq $RunBatch -and $DistributedStatementCount -gt 0) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Gathering data from query insights.")

        # Wait for the queries to show up in query insights or for X minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForQueryInsightsData)
        $ContinueLoop = $true

        # Look at query insights on the database where the batch ran to gather additional metrics.
        do {
            # Continue to look in query insights until all the queries are found.
            $Query = "
                WITH QueryInsights AS (
                    SELECT
                        UPPER(distributed_statement_id) AS DistributedStatementID,
                        session_id AS SessionID,
                        login_name AS LoginName,
                        CONVERT(NVARCHAR, submit_time, 21) AS SubmitTime,
                        CONVERT(NVARCHAR, start_time, 21) AS StartTime,
                        CONVERT(NVARCHAR, end_time, 21) AS EndTime,
                        total_elapsed_time_ms AS DurationInMS,
                        allocated_cpu_time_ms AS AllocatedCPUTimeMS,
                        data_scanned_remote_storage_mb AS DataScannedRemoteStorageMB,
                        data_scanned_memory_mb AS DataScannedMemoryMB,
                        data_scanned_disk_mb AS DataScannedDiskMB,
                        result_cache_hit AS ResultCacheHit,
                        row_count AS [RowCount],
                        [status] AS Status,
                        NULLIF([label], '') AS Label,
                        command AS Command
                    FROM queryinsights.exec_requests_history	
                )
                    
                SELECT
                    *
                FROM QueryInsights
                WHERE DistributedStatementID IN ({0})
            " -f $DistributedStatementIDListQueryInsights
            $QueryInsightsList = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query $Query
            
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in query insights is {0} and the current number is {1}." -f $DistributedStatementCount, $QueryInsightsList.Dataset.Tables.Rows.Count)
            
            # If the statement count has not been met and the time limit has not expired, wait for a minute and then check again.
            if (($QueryInsightsList.Dataset.Tables.Rows.Count -ne $DistributedStatementCount) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking query insights again.")
                Start-Sleep 60
            }
        
            # If the time limit has expired, stop checking for new queries.
            if ((Get-Date) -gt $WaitForJobsUntil) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in query insghts. Therefore, query insights data may be incomplete." -f $WaitTimeInMinutesForQueryInsightsData)
                $ContinueLoop = $false
            }
        } while (
            ($QueryInsightsList.Dataset.Tables.Rows.Count -ne $DistributedStatementCount) -and ($true -eq $ContinueLoop)
        )
        
        # Store the query insights results.
        if ($QueryInsightsList.Dataset.Tables.Rows.Count -gt 0) {
            $QueryInsights = $QueryInsightsList.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors
        }
    }

    # Gather details from capacity metrics. 
    if ($true -eq $CollectCapacityMetrics -and $true -eq $RunBatch -and $DistributedStatementCount -gt 0) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Gathering data from capacity metrics.")

        # Wait for the queries to show up in capacity metrics or for X minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForCapacityMetricsData)
        $ContinueLoop = $true

        # Look at capacity metrics gather the usage details.
        do {
            $CapacityMetrics = Get-FabricCapacityMetrics -CapacityMetricsWorkspace $CapacityMetricsWorkspace -CapacityMetricsSemanticModelName $CapacityMetricsSemanticModelName -Capacity $CapacityID -OperationIdList $DistributedStatementIDListCapacityMetrics -Date ([datetime]$BatchStartTime).ToString("yyyy-MM-dd 00:00:00") | Select-Object *, @{Name = "OperationCost"; Expression = {'{0:F6}' -f ([Math]::Round(($CapacityUnitPricePerHour / 60 / 60 * $_.CapacityUnitSeconds), 6))}}

            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in capacity metrics is {0} and the current number is {1}." -f $DistributedStatementCount, $CapacityMetrics.Count)

            # If the query count has not been met and the time limit has not expired, wait for a minute and then check again.
            if (($CapacityMetrics.Count -ne $DistributedStatementCount) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking capacity metrics again.")
                Start-Sleep 60
            }

            # If the time limit has expired, stop checking for new queries.
            if ((Get-Date) -gt $WaitForJobsUntil) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in capacity metrics. Therefore, capacity metrics data may be incomplete." -f $WaitTimeInMinutesForCapacityMetricsData)
                $ContinueLoop = $false
            }
        }
        while (
            ($CapacityMetrics.Count -ne $DistributedStatementCount) -and ($true -eq $ContinueLoop)
        )
    }

    # Write the results to the file system.
    if(!$Log) {$Log = @{}}
    if(!$LogQuery) {$LogQuery = @{}}
    if(!$LogStatement) {$LogStatement = @{}}
    if(!$LogQueryResult) {$LogQueryResult = @{}}
    if(!$QueryInsights) {$QueryInsights = @{}}
    if(!$CapacityMetrics) {$CapacityMetrics = @{}}

    $BatchNameLogFile = $BatchName.Replace('<', '_').Replace('>', '_').Replace(':', '_').Replace('"', '_').Replace('/', '_').Replace('\', '_').Replace('|', '_').Replace('?', '_').Replace('*', '_')

    $Log | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\Log.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogBatch | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\01_Batch.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogThread | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\02_Thread.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogIteration | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\03_Iteration.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogQuery | ConvertTo-Json -Depth 5 | Out-File (New-Item ("{0}\{1}_{2}\04_Query.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogQueryError | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\QueryError.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogQueryResult | ConvertTo-Json -Depth 3 -WarningAction SilentlyContinue | Out-File (New-Item ("{0}\{1}_{2}\QueryResult.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $LogStatement | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\05_Statement.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)   
    $QueryInsights | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\06_QueryInsights.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
    $CapacityMetrics | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\07_CapacityMetrics.txt" -f $LogDirectory, $BatchStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $BatchNameLogFile) -Force)
}