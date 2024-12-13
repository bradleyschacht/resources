<#
Capacity Metrics
Query Insights
Log
Query Log -> Query Requests (Distributed Statement IDs)
Query Results -> Query Log + Query Results



Log
Query
Query_Requests
Query_Insights
Query_CapacityMetrics
Query_Results
Query_Errors


{
"abc-def-123-456-ghi" :
    {
        Thread:
        Iteration:
        Query:
        Sequence:
        QueryID:
        Status:
        StartTime:
        EndTime:
        Retries:
        Errors:
        Success:
            Requests:
                DistributedStatementIDHere:
                    QueryInsights:
                    CapacityMetrics:
            Results:
    }

}


Clear-Host

$Var = @{}


$Key = "1"
$Var[$Key] = @{
    "Query" = 1
    "IterationCount" = 2
    "Iterations" = @{}
    "Status" = "Success"
}

$Var[$Key].Iterations["1"] = @{"Status" = "Failes"}
$Var[$Key].Iterations["2"] = @{
    "Status" = "Success"
    "Results" = "First"}

$Key = "2"
    $Var[$Key] = @{
        "Query" = 2
        "IterationCount" = 3
        "Iterations" = @{}
        "Status" = "Success"
    }
    
    $Var[$Key].Iterations["1"] = @{"Status" = "Failes"}
    $Var[$Key].Iterations["2"] = @{"Status" = "Failes"}
    $Var[$Key].Iterations["3"] = @{
        "Status" = "Success"
        "Results" = "Second"}




foreach ($i in $Var.keys) {

    if ($Var[$i].Status -eq "Success") {
        
        $Var[$i].Iterations[($Var[$i].IterationCount.ToString())]
    }

}






{
"abc-def-123-456-ghi" :
    {
        Thread:
        Iteration:
        Query:
        Sequence:
        Status:
        StartTime:
        EndTime:
        Retries?
        Errors
    }

}


#>

function Invoke-FabricBenchmark {
    param (
        # Scenario Details
        [Parameter(Mandatory=$true)] [string]$Scenario,
        [Parameter(Mandatory=$true)] [string]$WorkspaceName,
        [Parameter(Mandatory=$true)] [string]$ItemName,
        [Parameter(Mandatory=$true)] [string]$CapacitySubscriptionID,
        [Parameter(Mandatory=$true)] [string]$CapacityResourceGroupName,
        [Parameter(Mandatory=$true)] [string]$CapacityName,
        [Parameter(Mandatory=$true)] [string]$CapacitySize,
        [Parameter(Mandatory=$true)] [string]$Dataset,
        [Parameter(Mandatory=$true)] [string]$DataSize,
        [Parameter(Mandatory=$true)] [int32]$ThreadCount,
        [Parameter(Mandatory=$true)] [int32]$IterationCount,
        [Parameter(Mandatory=$true)] [string]$QueryDirectory,
        [Parameter(Mandatory=$true)] [string]$OutputDirectory,

        # Capacity Metrics
        [Parameter(Mandatory=$false)] [string]$CapacityMetricsWorkspace,
        [Parameter(Mandatory=$false)] [string]$CapacityMetricsSemanticModelName,

        # Runtime Variables
        [Parameter(Mandatory=$false)] [boolean]$CollectQueryInsights                      = $true,    <#  Default: $true  #>
        [Parameter(Mandatory=$false)] [boolean]$CollectCapacityMetrics                    = $true,    <#  Default: $true  #>
        [Parameter(Mandatory=$false)] [boolean]$PauseOnCapacitySkuChange                  = $false,   <#  Default: $false  #>
        [Parameter(Mandatory=$false)] [boolean]$StoreQueryResults                         = $false,   <#  Default: $false  #>
        [Parameter(Mandatory=$false)] [int32]$BatchTimeoutInMinutes                       = 120,      <#  Default: 120 minutes  #>
        [Parameter(Mandatory=$false)] [int32]$QueryRetryLimit                             = 0,        <#  Default: 1 -> The query will not retry on failure.  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInMinutesForQueryInsightsData       = 15,       <#  Default: 15  minutes  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInMinutesForCapacityMetricsData     = 15,       <#  Default: 15  minutes  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInSecondsAfterCapacitySkuChange     = 300,      <#  Default: 5 minutes -> 300 seconds  #>
        [Parameter(Mandatory=$false)] [int32]$WaitTimeInSecondsAfterCapacityResume        = 60        <#  Default: 1 minute  -> 60  seconds  #>
    )

    # Job Initialization Script
    $JobInitializationScript = {
        # Get the Fabric functions.
        (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Load%20Fabric%20Functions.ps1") | Invoke-Expression

        function Add-LogEntry {
            param (
                $Thread,
                $Iteration,
                $Query,
                $MessageType,
                $MessageText,
                $CodeBlock
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
                "CodeBlock"       = $CodeBlock
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
                Write-Host ("{0} | {1} | Thread {2} | Iteration {3} | Query {4} | {5} | {6}" -f $MessageTime, $MessageType, $Thread, $Iteration, $Query, $MessageText, $CodeBlock) -ForegroundColor Red
            }
            else {
                Write-Host ("{0} | {1} | Thread {2} | Iteration {3} | Query {4} | {5} | {6}" -f $MessageTime, $MessageType, $Thread, $Iteration, $Query, $MessageText, $CodeBlock)
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
            Write-Host "When `$CollectCapacityMetrics is set to `$true a value must be provided for the CapacityMetricsWorkspace and CapacityMetricsSemanticModelName parameters. The benchmark will not be run." -ForegroundColor Red
            Exit
        }
    }

    # Create the synchronized hashtable to store the log and thread status.
    $Log = [Hashtable]::Synchronized(@{})
    $ThreadStatus = [Hashtable]::Synchronized(@{})
    $QueryLog = [Hashtable]::Synchronized(@{})
    $QueryErrors = [Hashtable]::Synchronized(@{})
    $QueryRequests = [Hashtable]::Synchronized(@{})
    $QueryResults = [Hashtable]::Synchronized(@{})

    $Log.Clear()

    # Create the local log variable reference.
    $LocalLog = $Log

    $ScenarioStartTime = Get-Date

    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Scenario {0} has started." -f $Scenario) -CodeBlock $null
    
    # Call the various Fabric APIs to gather information about the environment. 
    $WorkspaceName                  = $WorkspaceName
    $CapacitySubscriptionID         = $CapacitySubscriptionID
    $CapacityResourceGroupName      = $CapacityResourceGroupName
    $CapacityName                   = $CapacityName
    $CapacitySize                   = $CapacitySize
    $ItemName                       = $ItemName

    # Get the workspace id.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to gather workspace id.") -CodeBlock $null
    $WorkspaceID = (Get-FabricWorkspace -Workspace $WorkspaceName).id

    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to capacity id.") -CodeBlock $null
    $CapacityID = (Get-FabricCapacity -Capacity $CapacityName).id

    # Get the capacity region.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get capacity region.") -CodeBlock $null
    $CapacityRegion = (Get-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName).location

    # Get the CU price per hour for the capacity's region.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get capacity CU price per hour.") -CodeBlock $null
    $CapacityCUPricePerHour = (Get-FabricCUPricePerHour -Region $CapacityRegion).Items.retailPrice
    
    # Determine if the item is a lakehouse or a warehouse, then gather the SQL connection string information.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get lakehouse information.") -CodeBlock $null
    $Lakehouse = Get-FabricLakehouse -Workspace $WorkspaceID -Lakehouse $ItemName
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Calling API to get warehouse information.") -CodeBlock $null
    $Warehouse = (Get-FabricWarehouse -Workspace $WorkspaceID -Warehouse $ItemName)
    if ($null -ne $Lakehouse.id) {
        $ItemID     = $Lakehouse.id
        $ItemType   = $Lakehouse.type
        $Server     = $Lakehouse.sqlEndpointProperties.connectionString
    }
    elseif ($null -ne $Warehouse.id) {
        $ItemID     = $Warehouse.id
        $ItemType   = $Warehouse.type
        $Server     = $Warehouse.connectionString
    }
    else {
        "Unknown item type."
    }

    # If any variables are still empty or $null then don't run the scenario.
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
        [string]::IsNullOrEmpty($CapacityCUPricePerHour) -or `
        [string]::IsNullOrEmpty($CapacityID)
    ) {
        $RunScenario = $false
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("At least one scenario lookup value was not found. The scenario will be terminated.") -CodeBlock $null
    }
    else {
        $RunScenario = $true
    }

    # Write the parameters to the console and the log.
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Workspace: {0}" -f $WorkspaceName) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("WorkspaceID: {0}" -f $WorkspaceID) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("ItemID: {0}" -f $ItemID) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("ItemName: {0}" -f $ItemName) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("ItemType: {0}" -f $ItemType) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Server: {0}" -f $Server) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacitySubscriptionID: {0}" -f $CapacitySubscriptionID) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityResourceGroupName: {0}" -f $CapacityResourceGroupName) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityName: {0}" -f $CapacityName) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacitySize: {0}" -f $CapacitySize) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityRegion: {0}" -f $CapacityRegion) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityCUPricePerHour: {0}" -f $CapacityCUPricePerHour) -CodeBlock $null
    Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("CapacityID: {0}" -f $CapacityID) -CodeBlock $null
    
    # Perform the necessary capacity related functions (Assign, scale, and resume) then check to be sure the SQL endpoint is accessible. 
    if ($true -eq $RunScenario) {
        # Assign the correct capacity for this scenario to the workspace.
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Assigning capacity to the workspace.") -CodeBlock $null
        $null = Set-FabricWorkspaceCapacity -Workspace $WorkspaceID -Capacity $CapacityID
        
        # Get the capacity's current state and SKU.
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Checking capacity SKU and status.") -CodeBlock $null
        $CapacityCurrent = Get-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName
        
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity current state: {0}" -f $CapacityCurrent.properties.state) -CodeBlock $null
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity current SKU: {0}" -f $CapacityCurrent.sku.name) -CodeBlock $null
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity expected SKU: {0}" -f $CapacitySize) -CodeBlock $null

        # Check if the current vs. expected SKUs match. If they don't, scale the capacity.
        if ($CapacityCurrent.sku.name -ne $CapacitySize) {
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Capacity SKUs do not match.") -CodeBlock $null
            
            # Pause the capacity if it is running so that the current activity is cleared.
            if (($CapacityCurrent.properties.state -ne "Paused") -and ($true -eq $PauseOnCapacitySkuChange)) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Pausing the capacity before scaling.") -CodeBlock $null
                $null = Suspend-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName                
            }

            # Scale the capacity to the proper SKU.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Initiating a scale operation.") -CodeBlock $null
            $CapacityCurrent = Set-FabricAzCapacitySku -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName -Sku $CapacitySize
            
            # Wait for x seconds after a SKU change.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting {0} seconds after a scaling operation." -f $WaitTimeInSecondsAfterCapacitySkuChange) -CodeBlock $null
            Start-Sleep -Seconds $WaitTimeInSecondsAfterCapacitySkuChange
        }

        # Resume the capacity if it is not running.
        if ($CapacityCurrent.properties.state -ne "Active") {
            # Start the capacity.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The capacity is paused. Resuming the capacity.") -CodeBlock $null
            $null = Resume-FabricAzCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName
            
            # Wait for x seconds after the capacity becomes active.
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting {0} seconds after a capacity resume operation." -f $WaitTimeInSecondsAfterCapacityResume) -CodeBlock $null
            Start-Sleep -Seconds $WaitTimeInSecondsAfterCapacityResume
        }

        # Set the variables for the SQL endpoint check loop.
        $RetryLimit = 2
        $RetryCount = 1
        $SQLEndpointActive = $false

        do {
            try {
                # Run a query against the database to see if it can connect and return a result.
                $null = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query "SELECT TOP 1 * FROM sys.databases"
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("SQL endpoint is online and responding.") -CodeBlock $null
                
                # Set the varaibles to indicate the batch should be run and the SQL endpoint check loop is complete.
                $RunScenario = $true
                $SQLEndpointActive = $true
            }
            catch {
                # Set the variables to not run the batch if the SQL endpoint check fails and iterate to the next check loop.
                $RunScenario = $false
                $RetryCount = $RetryCount + 1
                
                # If the loop has reached its retry limit, terminate the scenario. 
                if ($RetryCount -gt $RetryLimit) {
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1)) -CodeBlock $null
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ($_.Exception.Message) -CodeBlock $null
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("SQL endpoint check retry limit has been met. Terminating the SQL endpoint check and the scenario.") -CodeBlock $null
                }
                # If the loop has not reached its limit, wait and try again.
                else {
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Warning" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1)) -CodeBlock $null
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Warning" -MessageText ($_.Exception.Message) -CodeBlock $null
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Warning" -MessageText ("SQL endpoint check retry limit has not been met. Rechecking the SQL endpoint in 60 seconds.") -CodeBlock $null
                    Start-Sleep -Seconds 60
                }     
            }
        } until (
            # Continue running the loop until the SQL endpoint is active or the retry limit is reached.
            ($true -eq $SQLEndpointActive) -or ($RetryCount -gt $RetryLimit)
        )
    }

    if ($true -eq $RunScenario) {
        $ParallelThreads = foreach ($Thread in 1..$ThreadCount) {
            # Set the job name for the thread.
            $JobName = "Thread_{0}_{1}" -f $Thread, (New-Guid)

            # Start the job
            Start-ThreadJob `
            -Name $JobName `
            -StreamingHost $Host `
            -InitializationScript $JobInitializationScript `
            -ThrottleLimit $ThreadCount `
            -ArgumentList ($Thread, $ThreadCount, $ItemName, $Server, $IterationCount, $QueryRetryLimit, $QueryDirectory, $StoreQueryResults) `
            -ScriptBlock {
                param(
                    $Thread,
                    $ThreadCount,
                    $ItemName,
                    $Server,
                    $IterationCount,
                    $QueryRetryLimit,
                    $QueryDirectory,
                    $StoreQueryResults
                )

                $ThreadStartTime = Get-Date

                # Create the local log variable reference for the synchronized hashtable.
                $LocalLog = $using:Log

                Add-LogEntry -Thread $Thread -Iteration $null -MessageType "Information" -MessageText ("Thread {0} of {1} has started." -f $Thread, $ThreadCount) -CodeBlock $null

                # Create the local thread varaible reference for the synchronized hashtable.
                $LocalThreadStatus = $using:ThreadStatus

                # Create the local query log varaible reference for the synchronized hashtable.
                $LocalQueryLog = $using:QueryLog
                $LocalQueryErrors = $using:QueryErrors
                $LocalQueryRequests = $using:QueryRequests
                $LocalQueryResults = $using:QueryResults

                # Add a record indicating that the thread has started.
                $LocalThreadStatus[$Thread] = "Started"

                # Wait for all the other threads to start before running anything. 
                do {
                    Start-Sleep -Milliseconds 500
                } while (
                    $LocalThreadStatus.Count -lt $ThreadCount
                )

                Add-LogEntry -Thread $Thread -Iteration $null -MessageType "Information" -MessageText ("Thread {0} of {1} detected all other threads have initialized." -f $Thread, $ThreadCount) -CodeBlock $null

                foreach ($Iteration in 1..$IterationCount) {
                    $IterationStartTime = Get-Date
                    
                    Add-LogEntry -Thread $Thread -Iteration $IterationID -MessageType "Information" -MessageText ("Iteration {0} of {1} has started." -f $Iteration, $IterationCount) -CodeBlock $null
                    
                    $QueryList = Get-ChildItem -Path $QueryDirectory -File
                    
                    Add-LogEntry -Thread $Thread -Iteration $Iteration -MessageType "Information" -MessageText ("{0} queries(s) will be run in series." -f ($QueryList | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null

                    $QuerySequence = 0
                    
                    # Loop over each query and run then in series.
                    foreach($CurrentQuery in $QueryList) {
                        # Set the variables for the query run loop.
                        $QuerySequence++
                        $ContinueLoop = $true
                        $RetryCount = 0
                        $RetryLimit = $QueryRetryLimit
                        $QueryID = (New-Guid).ToString()

                        do {
                            try {                                
                                # Reset the query output variables.
                                $QueryResults = $null
                                $QueryOutput = $null
                                $QuerySuccessful = $false
                                
                                # Run the current query and collect the output for parsing.
                                $Query = Get-Content -Path $CurrentQuery.FullName -Raw
                                Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Query {0} of {1}" -f $QuerySequence, ($QueryList | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null
                                $QueryOutput = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query $Query
                                
                                # Check the query output for errors. 
                                if ($QueryOutput.Errors.Count -gt 0) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ("An error was found when parsing the query error output.") -CodeBlock $null

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
                                Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Query execution has ended successfully.") -CodeBlock $null
                            }
                            catch {
                                $ErrorKey = (New-Guid).ToString()
                                
                                # Build the message hashtable.
                                $Message = @{
                                    "QueryID"    = $QueryID
                                    "Error"      = $_.Exception.Message
                                }
                                # $LocalQueryRequests[$QueryRequestsKey] = $Message
                                $LocalQueryErrors[$ErrorKey] = $Message

                                # If there was an error and the retry limit has been reached raise an error.
                                if ($RetryCount -ge $RetryLimit) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Error" -MessageText ("Query has encountered an error.") -CodeBlock $null
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Error" -MessageText ($_.Exception.Message) -CodeBlock $null
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Error" -MessageText ("Query retry limit has been met ({0} of {1}). Exiting retry loop and terminating iteration." -f $RetryCount, $RetryLimit) -CodeBlock $null
                                    $ContinueLoop = $false
                                }
                                # If there was an error and the retry limit has not been reached raise a warning then retry the query.
                                else {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ("Query has encountered an error.") -CodeBlock $null
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ($_.Exception.Message) -CodeBlock $null
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Warning" -MessageText ("Query retry limit has not been met ({0} of {1}). Retry loop will attempt to rerun the query in 10 seconds." -f $RetryCount, $RetryLimit) -CodeBlock $null
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
                            $DistributedStatementIDCount = 0

                            # For each message in the query output check to see if it contains a distributed statement id for a query that was executed. If it does, log it. There could be multiple distributed statement ids per query executed by the script (for example a stored procedure may run multiple queries).
                            Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has started.") -CodeBlock $null
                            foreach ($Message in $QueryOutput.Messages) {
                                # Parse the message to see if it contains a distributed statement id.
                                $ParsedMessage = Find-FabricSQLMessage -Message $Message

                                # If it does contain a distributed statement id, log it to the query log. 
                                if ($null -ne $ParsedMessage.StatementID) {
                                    # There is a distributed statement id. Generate the command to write it to the log table.
                                    $DistributedStatementIDCount += 1

                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Iteration {0} of {1} has detected a query statement id. The distributed statement id {2} will be written to the query log." -f $Iteration.Iteration, $Iteration.IterationCount, $ParsedMessage.StatementID) -CodeBlock $null

                                    # $QueryRequestsKey = (New-Guid).ToString()

                                    # Build the message hashtable.
                                    $Message = @{
                                        "QueryID"                = $QueryID
                                        "QueryMessage"           = $ParsedMessage.Message
                                        "DistributedStatementID" = $ParsedMessage.StatementID
                                        "DistributedRequestID"   = $ParsedMessage.DistributedRequestID
                                        "QueryHash"              = $ParsedMessage.QueryHash
                                    }
                                    # $LocalQueryRequests[$QueryRequestsKey] = $Message
                                    $LocalQueryRequests[$ParsedMessage.StatementID] = $Message
                                }
                                else {
                                    # Do nothing.
                                }
                            }
                        
                            Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has ended.") -CodeBlock $null


                            if ($QueryOutput.Dataset.Tables.Count -gt 0 -and ($true -eq $StoreQueryResults -or ($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog"))) {
                                if ($true -eq $StoreQueryResults) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName  -MessageType "Information" -MessageText ("The query results will be stored on the iteration log record.") -CodeBlock $null    
                                }

                                if (($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog")) {
                                    Add-LogEntry -Thread $Thread -Iteration $Iteration -Query $CurrentQuery.BaseName  -MessageType "Information" -MessageText ("A custom query log was detected and will be stored on the iteration log record.") -CodeBlock $null
                                }

                                # Build the message hashtable.
                                $Message = @{
                                    "QueryID"   = $QueryID
                                    "Results"   = $(if ($true -eq $StoreQueryResults) {$QueryOutput.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors})
                                    "CustomLog" = $(if (($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog")) {$QueryOutput.Dataset.Tables[-1].Rows.QueryCustomLog})
                                }

                                $LocalQueryResults[$QueryID] = $Message
                            }                       
                        }
                    
                        # Build the message hashtable.
                        $Message = @{
                            "QueryID"                   = $QueryID
                            "Thread"                    = $Thread
                            "Iteration"                 = $Iteration
                            "Sequence"                  = $QuerySequence
                            "Query"                     = $CurrentQuery.BaseName
                            "Status"                    = $(if ($false -eq $QuerySuccessful) {"Failure"} elseif ($true -eq $QuerySuccessful -and -$RetryCount -gt 0) {"Success after retry"} elseif ($true -eq $QuerySuccessful -and $RetryCount -eq 0) {"Success"} else {"Unknown Status"})
                            "StartTime"                 = $(if ($true -eq $QuerySuccessful) {"{0}" -f $QueryOutput.QueryStartTime})
                            "EndTime"                   = $(if ($true -eq $QuerySuccessful) {"{0}" -f $QueryOutput.QueryEndTime})
                            "DistributedStatementCount" = $DistributedStatementIDCount
                            "QueryRequests"             = $LocalQueryRequests
                            "RetryCount"                = $RetryCount
                            "RetryLimit"                = $RetryLimit
                            "ResultsRecordCount"        = $QueryOutput.Dataset.Tables.Rows.Count
                            "Errors"                    = $(if ($false -eq $QuerySuccessful -or $RetryCount -gt 0) {$true} else {$true})
                            "QueryText"                 = $Query
                            "QueryMessage"              = $(if ($true -eq $QuerySuccessful) {$QueryOutput.Messages})
                        }

                        $LocalQueryLog[$QueryID] = $Message
                    }
                    
                    $IterationEndTime = Get-Date
                    Add-LogEntry -Thread $Thread -Iteration $Iteration -MessageType "Information" -MessageText ("Iteration {0} of {1} has ended." -f $Iteration, $IterationCount) -CodeBlock $null
                }

                $ThreadEndTime = Get-Date
                Add-LogEntry -Thread $Thread -Iteration $null -MessageType "Information" -MessageText ("Thread {0} of {1} has ended." -f $Thread, $ThreadCount) -CodeBlock $null
            }
        }

        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting for parallel threads to complete.") -CodeBlock $null

        # Let the threads run for up to X minutes before stopping them.
        $WaitForJobsUntil = (Get-Date).AddMinutes($BatchTimeoutInMinutes)
        $ContinueLoop = $true

        # Code to write the log to the console while waiting for threads to complete.
        do {
            if ((Get-Date) -gt $WaitForJobsUntil) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("The batch has reached the timeout limit of {0} minutes." -f $BatchTimeoutInMinutes) -CodeBlock $null
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("{0} of {1} thread(s) are running and will be stopped." -f ((Get-Job -State "Running").count), $ThreadCount) -CodeBlock $null
                foreach ($Job in (Get-Job -State "Running")) {
                    $Job | Stop-Job
                    Add-LogEntry -Thread $null -Iteration $null -MessageType "Error" -MessageText ("The thread {0} has been stopped." -f $job.Name) -CodeBlock $null
                }
            }

            Start-Sleep -Seconds 10
        } while (
            ((Get-Job -State "Running").count -gt 0) -and ($true -eq $ContinueLoop)
        )

        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("All parallel threads have completed.") -CodeBlock $null

        # Clean up all the completed jobs.
        foreach ($Job in (Get-Job -State "Completed")) {
            $Job | Remove-Job
        }

        <#
            Notes for later: Put a script here to go add an end record to all threads that were terminated
        #>

        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("All threads have been cleaned up.") -CodeBlock $null
        
        $ScenarioEndTime = Get-Date
    }

    if (($true -eq $CollectQueryInsights -or $true -eq $CollectCapacityMetrics) -and $true -eq $RunScenario) {
        # Get the list of distributed statement ids that need to have additional metrics collected from query insights or capacity metrics.
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from the query log.") -CodeBlock $null
        $DistributedStatementIDCount = ($QueryRequests.Values.DistributedStatementID | Measure-Object | Select-Object -ExpandProperty Count)
        
        
        if ($DistributedStatementIDCount -gt 0) {
            $QueryInsightsDistributedStatementIDList = ("'{0}'" -f ($QueryRequests.Values.DistributedStatementID -join "','")).ToUpper()
            $CapacityMetricsDistributedStatementIDList = ($QueryRequests.Values.DistributedStatementID).ToUpper()

            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $DistributedStatementIDCount) -CodeBlock $null
        }
        else {
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("No distributed statement ids were found in the query log.") -CodeBlock $null
        }
    }

    # Gather details from query insights. 
    if ($true -eq $CollectQueryInsights -and $true -eq $RunScenario -and $DistributedStatementIDCount -gt 0) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from query insights.") -CodeBlock $null

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
                        command AS QueryText
                    FROM queryinsights.exec_requests_history	
                )
                    
                SELECT
                    *
                FROM QueryInsights
                WHERE DistributedStatementID IN ({0})
            " -f $QueryInsightsDistributedStatementIDList
            $QueryInsightsList = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query $Query
            
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in query insights is {0} and the current number is {1}." -f $DistributedStatementIDCount, $QueryInsightsList.Dataset.Tables.Rows.Count) -CodeBlock $null
            
            # If the query count has not been met and the time limit has not expired, wait for a minute and then check again.
            if (($QueryInsightsList.Dataset.Tables.Rows.Count -ne $DistributedStatementIDCount) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking query insights again.") -CodeBlock $null
                Start-Sleep 60
            }
        
            # If the time limit has expired, stop checking for new queries.
            if ((Get-Date) -gt $WaitForJobsUntil) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in query insghts. Therefore, query insights metrics may be incomplete." -f $WaitTimeInMinutesForQueryInsightsData) -CodeBlock $null
                $ContinueLoop = $false
            }
        } while (
            ($QueryInsightsList.Dataset.Tables.Rows.Count -ne $DistributedStatementIDCount) -and ($true -eq $ContinueLoop)
        )
        
        # Store the query insights results.
        if ($QueryInsightsList.Dataset.Tables.Rows.Count -gt 0) {
            $QueryInsights = $QueryInsightsList.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors
            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has started.") -CodeBlock $null



            foreach($QueryInsightsRecord in ($QueryInsightsList.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors)) {
                $DistributedStatementID = $QueryInsightsRecord.DistributedStatementID
                Write-Host $DistributedStatementID
                $QueryLog.Values
                $QueryLog.Values.QueryRequests
                $QueryLog.Values.QueryRequests.$DistributedStatementID
                $QueryLog.Values.QueryRequests.$DistributedStatementID.QueryInsights = $QueryInsightsRecord | ConvertTo-Json | ConvertFrom-Json -AsHashTable
            }



            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has ended.") -CodeBlock $null
        }
    }

    # Gather details from capacity metrics. 
    if ($true -eq $CollectCapacityMetrics -and $true -eq $RunScenario -and $DistributedStatementIDCount -gt 0) {
        Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Gathering CU usage from capacity metrics.") -CodeBlock $null

        # Wait for the queries to show up in capacity metrics or for X minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForCapacityMetricsData)
        $ContinueLoop = $true

        # Look at capacity metrics gather the usage details.
        do {
            $CapacityMetrics = Get-FabricCapacityMetrics -CapacityMetricsWorkspace $CapacityMetricsWorkspace -CapacityMetricsSemanticModelName $CapacityMetricsSemanticModelName -Capacity $CapacityID -OperationIdList $CapacityMetricsDistributedStatementIDList -Date ([datetime]$ScenarioStartTime).ToString("yyyy-MM-dd 00:00:00")

            Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in capacity metrics is {0} and the current number is {1}." -f $DistributedStatementIDCount, $CapacityMetrics.Count) -CodeBlock $null

            # If the query count has not been met and the time limit has not expired, wait for a minute and then check again.
            if (($CapacityMetrics.Count -ne $DistributedStatementIDCount) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking capacity metrics again.") -CodeBlock $null
                Start-Sleep 60
            }

            # If the time limit has expired, stop checking for new queries.
            if ((Get-Date) -gt $WaitForJobsUntil) {
                Add-LogEntry -Thread $null -Iteration $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in capacity metrics. Therefore, columns in the query log that contain capacity metrics may be incomplete." -f $WaitTimeInMinutesForCapacityMetricsData) -CodeBlock $null
                $ContinueLoop = $false
            }
        }
        while (
            ($CapacityMetrics.Count -ne $DistributedStatementIDCount) -and ($true -eq $ContinueLoop)
        )
    }

    # Write the results to the file system.
    if(!$Log) {$Log = @{}}
    if(!$QueryLog) {$QueryLog = @{}}
    if(!$QueryRequests) {$QueryRequests = @{}}
    if(!$QueryResults) {$QueryResults = @{}}
    if(!$QueryInsights) {$QueryInsights = @{}}
    if(!$CapacityMetrics) {$CapacityMetrics = @{}}

    $Log | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\Log.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    $QueryLog | ConvertTo-Json -Depth 5 | Out-File (New-Item ("{0}\{1}_{2}\QueryLog.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    $QueryErrors | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\QueryErrors.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    $QueryRequests | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\QueryRequests.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    $QueryResults | ConvertTo-Json -Depth 3 -WarningAction SilentlyContinue | Out-File (New-Item ("{0}\{1}_{2}\QueryResults.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    $QueryInsights | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\QueryInsights.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    $CapacityMetrics | ConvertTo-Json | Out-File (New-Item ("{0}\{1}_{2}\CapacityMetrics.txt" -f $OutputDirectory, $ScenarioStartTime.ToString("yyyy-MM-dd_HH.mm.ss"), $Scenario) -Force)
    
}