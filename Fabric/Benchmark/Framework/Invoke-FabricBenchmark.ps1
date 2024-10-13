function Invoke-FabricBenchmark {
    param (
        # Flight Control Database
        [Parameter(Mandatory=$true)]
        [string]$FlightControlServer,
        [Parameter(Mandatory=$true)]
        [string]$FlightControlDatabase,    
    
        # Scenario Filters
        [string]$WorkspaceName = $null,
        [array]$ScenarioList = @(),

        # Capacity Metrics
        [string]$CapacityMetricsWorkspace,
		[string]$CapacityMetricsSemanticModelName = "Fabric Capacity Metrics",
		[string]$CapacityMetricsSemanticModelId,

        <#
            Notes for later: Enable the real time write to a log file locally.
            
            # Log Storage Location
            [string]$BatchLogFolder = $null,
        #>

        # Runtime Variables
        [boolean]$GenerateNewScenarios                      = $true,    <#  Default: $true  #>
        [boolean]$CollectQueryInsights                      = $true,    <#  Default: $true  #>
        [boolean]$CollectCapacityMetrics                    = $true,    <#  Default: $true  #>
        [boolean]$PauseOnCapacitySkuChange                  = $false,   <#  Default: $false  #>
        [boolean]$StoreQueryResultsOnQueryRecord            = $false,   <#  Default: $false  #>
        [int32]$BatchTimeoutInMinutes                       = 120,      <#  Default: 120 minutes  #>
        [int32]$QueryRetryLimit                             = 1,        <#  Default: 1 -> The query will not retry on failure.  #>
        [int32]$WaitTimeInMinutesForQueryInsightsData       = 15,       <#  Default: 15  minutes  #>
        [int32]$WaitTimeInMinutesForCapacityMetricsData     = 15,       <#  Default: 15  minutes  #>
        [int32]$WaitTimeInSecondsAfterCapacitySkuChange     = 300,      <#  Default: 5 minutes -> 300 seconds  #>
        [int32]$WaitTimeInSecondsAfterCapacityResume        = 60        <#  Default: 1 minute  -> 60  seconds  #>
    )

    # Job Initialization Script
    $JobInitializationScript = {
        # Get the Fabric functions.
        (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Fabric%20Functions.ps1") | Invoke-Expression

        function Add-LogEntry {
            param (
                $ScenarioID,    
                $BatchID,
                $ThreadID,
                $IterationID,
                $QueryID = $null,
                $MessageType,
                $MessageText,
                $CodeBlock
            )

            # Generate a key for the log record.
            $LogKey = (New-Guid).ToString()
            $MessageTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss.ffff")
            
            # Build the message hashtable.
            $Message = @{
                "ScenarioID"            = $ScenarioID
                "BatchID"               = $BatchID
                "ThreadID"              = $ThreadID
                "IterationID"           = $IterationID
                "QueryID"               = $QueryID
                "MessageType"           = $MessageType
                "MessageTime"           = $MessageTime
                "MessageText"           = $MessageText
                "CodeBlock"             = $CodeBlock
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
                Write-Host ("{0} | {1} | ScenarioID {2} | BatchID {3} | ThreadID {4} | IterationID {5} | QueryID {6} | {7} | {8}" -f $MessageTime, $MessageType, $ScenarioID, $BatchID, $ThreadID, $IterationID, $QueryID, $MessageText, $CodeBlock) -ForegroundColor Red
            }
            else {
                Write-Host ("{0} | {1} | ScenarioID {2} | BatchID {3} | ThreadID {4} | IterationID {5} | QueryID {6} | {7} | {8}" -f $MessageTime, $MessageType, $ScenarioID, $BatchID, $ThreadID, $IterationID, $QueryID, $MessageText, $CodeBlock)
            }

            <#
                Notes for later: Enable the real time write to a log file locally.
                
                # Write the message to the log.
                Write-Output ($Message | ConvertTo-JSON | Out-String) | Out-File $LogFilePath -Append
            #>
        }
    }

    # Write out the variables for the run.
    Write-Host "*************************************************************************************"
    Write-Host ""
    Write-Host "***  Workspace Filter  ***"
    Write-Host ("{0}: {1}" -f "WorkspaceName", $WorkspaceName)
    Write-Host ("{0}: {1}" -f "ScenarioList", $($ScenarioList -join ", "))
    Write-Host ""
    Write-Host "***  Flight Control Database  ***"
    Write-Host ("{0}: {1}" -f "FlightControlServer", $FlightControlServer)
    Write-Host ("{0}: {1}" -f "FlightControlDatabase", $FlightControlDatabase)
    Write-Host ""
    Write-Host "***  Capacity Metrics  ***"
    Write-Host ("{0}: {1}" -f "CapacityMetricsWorkspace", $CapacityMetricsWorkspace)
    Write-Host ("{0}: {1}" -f "CapacityMetricsSemanticModelName", $CapacityMetricsSemanticModelName)
    Write-Host ("{0}: {1}" -f "CapacityMetricsSemanticModelId", $CapacityMetricsSemanticModelId)
    Write-Host ""
    <#
        Notes for later: If enabling the local log, write this location to the console.
        
        # Write-Host "***  Log Storage Location  ***"
        # Write-Host ("{0}: {1}" -f "BatchLogFolder", $BatchLogFolder)
        # Write-Host ""
    #>
    Write-Host "***  Runtime Variables  ***"
    Write-Host ("{0}: {1}" -f "GenerateNewScenarios", $GenerateNewScenarios)
    Write-Host ("{0}: {1}" -f "CollectQueryInsights", $CollectQueryInsights)
    Write-Host ("{0}: {1}" -f "CollectCapacityMetrics", $CollectCapacityMetrics)
    Write-Host ("{0}: {1}" -f "PauseOnCapacitySkuChange", $PauseOnCapacitySkuChange)
    Write-Host ("{0}: {1}" -f "StoreQueryResultsOnQueryRecord", $StoreQueryResultsOnQueryRecord)
    Write-Host ("{0}: {1}" -f "BatchTimeoutInMinutes", $BatchTimeoutInMinutes)
    Write-Host ("{0}: {1}" -f "QueryRetryLimit", $QueryRetryLimit)
    Write-Host ("{0}: {1}" -f "WaitTimeInMinutesForQueryInsightsData", $WaitTimeInMinutesForQueryInsightsData)
    Write-Host ("{0}: {1}" -f "WaitTimeInMinutesForCapacityMetricsData", $WaitTimeInMinutesForCapacityMetricsData)
    Write-Host ("{0}: {1}" -f "WaitTimeInSecondsAfterCapacitySkuChange", $WaitTimeInSecondsAfterCapacitySkuChange)
    Write-Host ("{0}: {1}" -f "WaitTimeInSecondsAfterCapacityResume", $WaitTimeInSecondsAfterCapacityResume)
    Write-Host ""
    Write-Host "*************************************************************************************"
    Write-Host ""
    Write-Host ""

    # Load all the functions.
    Invoke-Expression ($JobInitializationScript | Out-String)

    # Check to be sure the required parameters are provided.
    if ($null -eq $FlightControlServer -or $FlightControlServer -eq "" -or $null -eq $FlightControlDatabase -or $FlightControlDatabase -eq "") {
        if($null -eq $FlightControlServer -or $FlightControlServer -eq "") {
            Write-Host "The FlightControlServer parameter was empty." -ForegroundColor Red
        }

        if($null -eq $FlightControlDatabase -or $FlightControlDatabase -eq "") {
            Write-Host "The FlightControlDatabase parameter was empty." -ForegroundColor Red
        }
        
        Write-Host "Missing required parameters. The benchmark will not be run." -ForegroundColor Red
        Exit
    }
    
    # Check to be sure the FlightControl database is accessible.
    try {
        # Run a query against the database to see if it can connect and return a result.
        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query "SELECT TOP 1 * FROM sys.databases"
    }
    catch {
        # If the loop has reached its retry limit, terminate the scenario. 
        Write-Host "Accessing the FlightControl database encountered an error. The benchmark will not be run." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Exit
    }

    # Check to be sure the proper Capacity Metrics parameter combination was passed.
    if ($true -eq $CollectCapacityMetrics) {
        if($CapacityMetricsSemanticModelId -ne "" -and $null -ne $CapacityMetricsSemanticModelId) {
            # Continue running the script.
        }
        elseif (($CapacityMetricsWorkspace -ne "" -and $null -ne $CapacityMetricsWorkspace) -and ($CapacityMetricsSemanticModelName -ne "" -and $null -ne $CapacityMetricsSemanticModelName)) {
            # Continue running the script.
        }
        else {
            Write-Host "No value was provided for the Capacity Metrics parameters." -ForegroundColor Red
            Write-Host "When `$CollectCapacityMetrics is set to `$true a value must be provided for the CapacityMetricsSemanticModelID or the CapacityMetricsWorkspace parameter. The benchmark will not be run." -ForegroundColor Red
            Exit
        }
    }

    # Generate new scenarios.
    if ($true -eq $GenerateNewScenarios) {
        Write-Host "Generating scenarios."

        $Query = "
            DECLARE @WorkspaceName			    NVARCHAR(200) = '{0}'
            DECLARE @ScenarioID					NVARCHAR(50)
            DECLARE @ScenarioID_New				INT
            DECLARE @ScenarioName				NVARCHAR(200)
            DECLARE @ItemName					NVARCHAR(200)
            DECLARE @CapacitySubscriptionID		NVARCHAR(200)
            DECLARE @CapacityResourceGroupName	NVARCHAR(200)
            DECLARE @CapacityName				NVARCHAR(200)
            DECLARE @CapacitySize				NVARCHAR(200)
            DECLARE @Dataset					NVARCHAR(200)
            DECLARE @DataSize					NVARCHAR(200)
            DECLARE @DataStorage				NVARCHAR(200)
            DECLARE @BatchID					INT
            DECLARE @BatchDescription			NVARCHAR(200)
            DECLARE @IterationCount				INT
            DECLARE @BatchFolder				NVARCHAR(500)

            SET @WorkspaceName = NULLIF(@WorkspaceName, 'NULL')
            SET @WorkspaceName = NULLIF(@WorkspaceName, '')            
            
            DECLARE Scenario CURSOR FOR
                SELECT
                    ScenarioID, ScenarioName, WorkspaceName, ItemName, CapacitySubscriptionID, CapacityResourceGroupName, CapacityName, CapacitySize, Dataset, DataSize, DataStorage
                FROM automation.Scenario
                WHERE 
                    -- Handle the automated cases where the records are active.
                    (
                        (
                            (
                                CASE
                                    -- No workspace is provdied and no list is provided then return everything (WHERE 1 = 1).
                                    WHEN (@WorkspaceName = '' OR @WorkspaceName IS NULL) AND '{1}' = '' THEN 1
                                    ELSE 0
                                    END = 1
                            )
                            OR
                            (
                                CASE
                                    -- A workspace is provided and no list is provided then return just the specified workspace.
                                    WHEN @WorkspaceName != '' AND @WorkspaceName IS NOT NULL AND '{1}' = '' THEN 1
                                    ELSE 0
                                    END = 1
                                AND WorkspaceName = @WorkspaceName
                            )
                        )
                        AND IsActive = 1
                    )
                    -- Handle overriding the automated batch list with a list of scenarios.
                    OR
                    (
                        CASE
                            WHEN '{1}' != '' THEN 1
                            ELSE 0
                            END = 1
                        AND ScenarioID IN ('{1}')
                    )
                ORDER BY
                    ScenarioSequence
            
            OPEN Scenario

            FETCH NEXT FROM Scenario INTO @ScenarioID, @ScenarioName, @WorkspaceName, @ItemName, @CapacitySubscriptionID, @CapacityResourceGroupName, @CapacityName, @CapacitySize, @Dataset, @DataSize, @DataStorage
            WHILE @@FETCH_STATUS = 0
                BEGIN

                    INSERT INTO dbo.Scenario (ScenarioName, Status, WorkspaceName, ItemName, CapacitySubscriptionID, CapacityResourceGroupName, CapacityName, CapacitySize, Dataset, DataSize, DataStorage, CreateTime, LastUpdateTime)
                    VALUES (@ScenarioName, 'Not Started', @WorkspaceName, @ItemName, @CapacitySubscriptionID, @CapacityResourceGroupName, @CapacityName, @CapacitySize, @Dataset, @DataSize, @DataStorage, GETDATE(), GETDATE())

                    SET @ScenarioID_New = (SELECT SCOPE_IDENTITY())
                
                    SET @BatchID = NULL

                    DECLARE Batch CURSOR FOR
                        SELECT
                            BatchDescription, IterationCount, BatchFolder
                        FROM automation.Batch
                        WHERE
                            IsActive = 1
                            AND ScenarioID = @ScenarioID
                        ORDER BY 
                            BatchSequence
                        
                    OPEN Batch

                    FETCH NEXT FROM Batch INTO @BatchDescription, @IterationCount, @BatchFolder
                    WHILE @@FETCH_STATUS = 0
                        BEGIN

                            INSERT INTO dbo.Batch (ParentBatchID, ScenarioID, BatchDescription, Status, IterationCount, BatchFolder, CreateTime, LastUpdateTime)
                            VALUES (@BatchID, @ScenarioID_New, @BatchDescription, 'Not Started', @IterationCount, @BatchFolder, GETDATE(), GETDATE())

                            SET @BatchID = (SELECT SCOPE_IDENTITY())

                        FETCH NEXT FROM Batch INTO @BatchDescription, @IterationCount, @BatchFolder
                        END

                    CLOSE Batch
                    DEALLOCATE BATCH

                FETCH NEXT FROM Scenario INTO @ScenarioID, @ScenarioName, @WorkspaceName, @ItemName, @CapacitySubscriptionID, @CapacityResourceGroupName, @CapacityName, @CapacitySize, @Dataset, @DataSize, @DataStorage
                END
            
            CLOSE Scenario
            DEALLOCATE Scenario    
        " -f $WorkspaceName, $($ScenarioList -join "','")
        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
    }

    # Get the list of scenarios to run.
    Write-Host "Getting scenario list."
    
    $Query = "
        DECLARE @WorkspaceName NVARCHAR(200) = '{0}'
            
        IF TRIM(@WorkspaceName) = '' OR @WorkspaceName IS NULL
            SELECT
                ScenarioID,
                WorkspaceName,
                ItemName,
                CapacitySubscriptionID,
                CapacityResourceGroupName,
                CapacityName,
                CapacitySize
            FROM dbo.Scenario
            WHERE
                StartTime IS NULL
            ORDER BY
                ScenarioID

        ELSE	
            SELECT
                ScenarioID,
                WorkspaceName,
                ItemName,
                CapacitySubscriptionID,
                CapacityResourceGroupName,
                CapacityName,
                CapacitySize

                -- Fields to look up if they aren't populated already. --
                WorkspaceID,
                ItemID,
                ItemType,
                Server,
                CapacityCUPricePerHour,
                CapacityRegion,
                CapacityID,
            FROM dbo.Scenario
            WHERE
                StartTime IS NULL
                AND WorkspaceName = @WorkspaceName
            ORDER BY
                ScenarioID
    " -f $WorkspaceName
    $Scenarios = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

    # Check to see if there are any scenarios in the resultset.
    if (($Scenarios | Measure-Object).Count -gt 0) {
        # If there are scenarios, loop over the list and run them in series.
        foreach($Scenario in $Scenarios) {
            $RunScenario = $true
            
            # Store the scenario id for easier use later in the script.
            $ScenarioID = $Scenario.ScenarioID

            # Create the synchronized hashtable to store the log and thread status.
            $Log = [Hashtable]::Synchronized(@{})
            $ThreadStatus = [Hashtable]::Synchronized(@{})

            $Log.Clear()

            # Initiate the scenario level log.
            # $LogFilePath = (Join-Path -Path $BatchLogFolder -ChildPath ("B{0} - {1}.txt" -f $BatchID, (Get-Date).ToUniversalTime().ToString("yyyy_MM_ddTHH_mm_ss_ffff")))    

            # Create the local log variable reference.
            $LocalLog = $Log

            # Start the current scenario.
            $Query = "
                UPDATE dbo.Scenario
                SET
                    Status = 'Running',
                    StartTime = GETDATE(),
                    LastUpdateTime = GETDATE()
                WHERE
                    ScenarioID = {0}
            " -f $ScenarioID
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Scenario {0} has started." -f $ScenarioID) -CodeBlock $null
            $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
            
            # Call the various Fabric APIs to gather information about the environment. 
            $WorkspaceName                  = $Scenario.WorkspaceName
            $CapacitySubscriptionID         = $Scenario.CapacitySubscriptionID
            $CapacityResourceGroupName      = $Scenario.CapacityResourceGroupName
            $CapacityName                   = $Scenario.CapacityName
            $CapacitySize                   = $Scenario.CapacitySize
            $ItemName                       = $Scenario.ItemName
            $Database                       = $Scenario.ItemName
            
            # Get the workspace id.
            if ($Scenario.WorkspaceID -eq "") {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to gather workspace id.") -CodeBlock $null
                $WorkspaceID = (Get-FabricWorkspace -Workspace $WorkspaceName).id
            }
            else {
                $WorkspaceID = $Scenario.WorkspaceID
            }

            # Get the capacity id.
            if ($Scenario.CapacityID -eq "") {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to capacity id.") -CodeBlock $null
                $CapacityID = (Get-FabricCapacity -Location "Fabric" -Capacity $Scenario.CapacityName).id
            }
            else {
                $CapacityID = $Scenario.CapacityID
            }

            # Get the capacity region.
            if ($Scenario.CapacityRegion -eq "") {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to get capacity region.") -CodeBlock $null
                $CapacityRegion = (Get-FabricCapacity -Location "Azure" -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName).location
            }
            else {
                $CapacityRegion = $Scenario.CapacityRegion
            }
            
            # Get the CU price per hour for the capacity's region.
            if ($Scenario.CapacityCUPricePerHour -eq "") {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to get capacity CU price per hour.") -CodeBlock $null
                $CapacityCUPricePerHour = Get-FabricCUPricePerHour -Region $CapacityRegion
            }
            else {
                $CapacityCUPricePerHour = $Scenario.CapacityCUPricePerHour
            }
            
            if ($Scenario.ItemID -eq "" -or $Scenario.ItemType -eq "" -or $Scenario.Server -eq "") {
                # Determine if the item is a lakehouse or a warehouse, then gather the SQL connection string information.
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to get lakehouse information.") -CodeBlock $null
                $Lakehouse = Get-FabricLakehouse -Workspace $WorkspaceID -Lakehouse $ItemName
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to get warehouse information.") -CodeBlock $null
                $Warehouse = (Get-FabricWarehouse -Workspace $WorkspaceID -Warehouse $ItemName)
                if ($null -ne $Lakehouse.id) {
                    $ItemID     = $Lakehouse.id
                    $ItemType   = $Lakehouse.type
                    $Server     = $Lakehouse.properties.sqlEndpointProperties.connectionString
                }
                elseif ($null -ne $Warehouse.id) {
                    $ItemID     = $Warehouse.id
                    $ItemType   = $Warehouse.type
                    $Server     = $Warehouse.properties.connectionString
                }
                else {
                    "Unknown item type."
                }
            }
            else {
                $ItemID = $Scenario.ItemID
                $ItemType = $Scenario.ItemType
                $Server = $Scenario.Server
            }

            # Update the scenario record with the information gathered from the API calls if any of the fields were blank.
            if ($Scenario.WorkspaceID -eq "" -or $Scenario.ItemID -eq "" -or $Scenario.ItemType -eq "" -or $Scenario.Server -eq "" -or $Scenario.CapacityCUPricePerHour -eq "" -or $Scenario.CapacityRegion -eq "" -or $Scenario.CapacityID -eq "") {
                $Query = "
                    UPDATE dbo.Scenario
                    SET
                        WorkspaceID = '{0}',
                        ItemID = '{1}',
                        ItemType = '{2}',
                        Server = '{3}',
                        CapacityCUPricePerHour = '{4}',
                        CapacityRegion = '{5}',
                        CapacityID = '{6}',
                        LastUpdateTime = GETDATE()
                    WHERE ScenarioID = {7}
                " -f $WorkspaceID, $ItemID, $ItemType, $Server, $CapacityCUPricePerHour, $CapacityRegion, $CapacityID, $ScenarioID
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Scenario lookup values have been updated.") -CodeBlock $null
                $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
            }

            # If any variables are still empty or $null then don't run the scenario.
            if (
                $null -eq $WorkspaceName -or $WorkspaceName.trim() -eq "" -or
                $null -eq $WorkspaceID -or $WorkspaceID.trim() -eq "" -or
                $null -eq $ItemID -or $ItemID.trim() -eq "" -or
                $null -eq $ItemName -or $ItemName.trim() -eq "" -or
                $null -eq $ItemType -or $ItemType.trim() -eq "" -or
                $null -eq $Server -or $Server.trim() -eq "" -or
                $null -eq $Database -or $Database.trim() -eq "" -or
                $null -eq $CapacitySubscriptionID -or $CapacitySubscriptionID.trim() -eq "" -or
                $null -eq $CapacityResourceGroupName -or $CapacityResourceGroupName.trim() -eq "" -or
                $null -eq $CapacityName -or $CapacityName.trim() -eq "" -or
                $null -eq $CapacitySize -or $CapacitySize.trim() -eq "" -or
                $null -eq $CapacityRegion -or $CapacityRegion.trim() -eq "" -or
                $null -eq $CapacityCUPricePerHour -or $CapacityCUPricePerHour.trim() -eq "" -or
                $null -eq $CapacityID -or $CapacityID.trim() -eq "" -or
                $null -eq $ThreadCount -or $ThreadCount.trim() -eq ""
            ) {
                $RunScenario = $false
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("At least one scenario lookup value was not found. The scenario will be terminated.") -CodeBlock $null
            }
            else {
                # Do nothing, $RunScenario is already set to $true.
            }
            
            # Write the parameters to the console and the log.
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Workspace: {0}" -f $WorkspaceName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("WorkspaceID: {0}" -f $WorkspaceID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ItemID: {0}" -f $ItemID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ItemName: {0}" -f $ItemName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ItemType: {0}" -f $ItemType) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Server: {0}" -f $Server) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Database: {0}" -f $Database) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacitySubscriptionID: {0}" -f $CapacitySubscriptionID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityResourceGroupName: {0}" -f $CapacityResourceGroupName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityName: {0}" -f $CapacityName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacitySize: {0}" -f $CapacitySize) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityRegion: {0}" -f $CapacityRegion) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityCUPricePerHour: {0}" -f $CapacityCUPricePerHour) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityID: {0}" -f $CapacityID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ThreadCount: {0}" -f $ThreadCount) -CodeBlock $null
            
            # Perform the necessary capacity related functions (Assign, scale, and resume) then check to be sure the SQL endpoint is accessible. 
            if ($true -eq $RunScenario) {
                # Assign the correct capacity for this scenario to the workspace.
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Assigning capacity to the workspace.") -CodeBlock $null
                $null = Set-FabricWorkspaceCapacity -Workspace $WorkspaceID -Capacity $CapacityID
                
                # Get the capacity's current state and SKU.
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Checking capacity SKU and status.") -CodeBlock $null
                $CapacityCurrent = Get-FabricCapacity -Location "Azure" -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName
                
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity current state: {0}" -f $CapacityCurrent.properties.state) -CodeBlock $null
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity current SKU: {0}" -f $CapacityCurrent.sku.name) -CodeBlock $null
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity expected SKU: {0}" -f $CapacitySize) -CodeBlock $null
        
                # Check if the current vs. expected SKUs match. If they don't, scale the capacity.
                if ($CapacityCurrent.sku.name -ne $CapacitySize) {
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity SKUs do not match.") -CodeBlock $null
                    
                    # Pause the capacity if it is running so that the current activity is cleared.
                    if (($CapacityCurrent.properties.state -ne "Paused") -and ($true -eq $PauseOnCapacitySkuChange)) {
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Pausing the capacity before scaling.") -CodeBlock $null
                        $null = Suspend-FabricCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName                
                    }
        
                    # Scale the capacity to the proper SKU.
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Initiating a scale operation.") -CodeBlock $null
                    $CapacityCurrent = Set-FabricCapacitySku -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName -Sku $CapacitySize
                    
                    # Wait for x seconds after a SKU change.
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting {0} seconds after a scaling operation." -f $WaitTimeInSecondsAfterCapacitySkuChange) -CodeBlock $null
                    Start-Sleep -Seconds $WaitTimeInSecondsAfterCapacitySkuChange
                }
        
                # Resume the capacity if it is not running.
                if ($CapacityCurrent.properties.state -ne "Active") {
                    # Start the capacity.
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The capacity is paused. Resuming the capacity.") -CodeBlock $null
                    $null = Resume-FabricCapacity -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -CapacityName $CapacityName
                    
                    # Wait for x seconds after the capacity becomes active.
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting {0} seconds after a capacity resume operation." -f $WaitTimeInSecondsAfterCapacityResume) -CodeBlock $null
                    Start-Sleep -Seconds $WaitTimeInSecondsAfterCapacityResume
                }
    
                # Set the variables for the SQL endpoint check loop.
                $RetryLimit = 2
                $RetryCount = 1
                $SQLEndpointActive = $false

                do {
                    try {
                        # Run a query against the database to see if it can connect and return a result.
                        $null = Invoke-FabricSQLCommand -Server $Server -Database $Database -Query "SELECT TOP 1 * FROM sys.databases"
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("SQL endpoint is online and responding.") -CodeBlock $null
                        
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
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1)) -CodeBlock $null
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ($_.Exception.Message) -CodeBlock $null
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("SQL endpoint check retry limit has been met. Terminating the SQL endpoint check and the scenario.") -CodeBlock $null
                        }
                        # If the loop has not reached its limit, wait and try again.
                        else {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Warning" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1)) -CodeBlock $null
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Warning" -MessageText ($_.Exception.Message) -CodeBlock $null
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Warning" -MessageText ("SQL endpoint check retry limit has not been met. Rechecking the SQL endpoint in 60 seconds.") -CodeBlock $null
                            Start-Sleep -Seconds 60
                        }     
                    }
                } until (
                    # Continue running the loop until the SQL endpoint is active or the retry limit is reached.
                    ($true -eq $SQLEndpointActive) -or ($RetryCount -gt $RetryLimit)
                )
            }

            # Build the scenario (Threads, Iterations, and Queries).
            if ($true -eq $RunScenario) {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Building the scenario.") -CodeBlock $null
                
                # Clear out the existing threads, iterations, and queries for the current scenario in case they are already in the tables from a previous, failed activity.
                $Query = "
                    DELETE FROM dbo.Thread WHERE ScenarioID = {0}
                    DELETE FROM dbo.Iteration WHERE ScenarioID = {0}
                    DELETE FROM dbo.Query WHERE ScenarioID = {0}
                " -f $ScenarioID
                $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                
                # Get a list of batches for this scenario.
                $Query = "
                    SELECT
                        BatchID,
                        IterationCount,
                        BatchFolder
                    FROM dbo.Batch
                    WHERE
                        ScenarioID = {0}
                    ORDER BY
                        BatchID
                " -f $ScenarioID
                $Batches = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

                # For each batch, populate the threads, iterations, and queries based on the folder structure found on the file system.
                foreach($Batch in $Batches) {
                    $BatchID = $Batch.BatchID
                    $BatchFolder = $Batch.BatchFolder
                    $IterationCount = $Batch.IterationCount

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Generating threads for Batch {0}." -f $BatchID) -CodeBlock $null
                    
                    # Get a list of threads. Each thread will have its own folder in the batch directory.
                    $ThreadList = Get-ChildItem -Path $BatchFolder -Directory | Sort-Object Name

                    # Set the thread count field on the batch record to reflect the number of threads in the batch directory.
                    $Query = "UPDATE dbo.Batch SET ThreadCount = {0}, BatchName = '{1}', LastUpdateTime = GETDATE() WHERE BatchID = {2}" -f $ThreadList.Count, (Split-Path -Path $BatchFolder -Leaf), $BatchID
                    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                    # For each thread (thread folder), get the list of queries and create the thread record.
                    $ThreadNumber = 0
                    foreach($Thread in $ThreadList) {
                        $ThreadNumber ++
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Generating Thread {0}." -f $ThreadNumber) -CodeBlock $null

                        # Get the query list for this thread. There will be one file per query.
                        $QueryList = Get-ChildItem -Path $Thread.FullName -File | Sort-Object Name

                        # Create the thread record and return the ThreadID.
                        $Query = "
                            INSERT INTO dbo.Thread (ScenarioID, BatchID, Thread, Status, ThreadName, ThreadFolder, CountOfQueries, CreateTime, LastUpdateTime)
                            VALUES ({5}, {0}, {1}, 'Not Started', '{2}', '{3}', {4}, GETDATE(), GETDATE());
                            SELECT SCOPE_IDENTITY() AS ThreadID;
                        " -f $BatchID, $ThreadNumber, $Thread.Name, $Thread.FullName, $QueryList.Count, $ScenarioID
                        $ThreadID = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows.ThreadID

                        # For each iteration, create the iteration record then handle the queries.
                        foreach($Iteration in 1..$IterationCount) {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Generating Iteration {0}." -f $Iteration) -CodeBlock $null
                            
                            # Create the iteration record and return the IterationID.
                            $Query = "
                                INSERT INTO dbo.Iteration (ScenarioID, BatchID, ThreadID, Iteration, Status, CreateTime, LastUpdateTime)
                                VALUES({3}, {0}, {1}, {2}, 'Not Started', GETDATE(), GETDATE());
                                SELECT SCOPE_IDENTITY() AS IterationID;
                            " -f $BatchID, $ThreadID, $Iteration, $ScenarioID
                            $IterationID = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows.IterationID

                            # Build a string to create all the query records at one time.
                            $QuerySequence = 0
                            $Query = "INSERT INTO dbo.Query (ScenarioID, BatchID, ThreadID, IterationID, QuerySequence, QueryFile, QueryName, Query, Status, CreateTime, LastUpdateTime) `r`nVALUES`r`n"
                            foreach($QueryFile in $QueryList) {
                                $QuerySequence ++
                                
                                # Read the file content to store it on the query record.
                                $FileContent = ""
                                $FileContent = Get-Content -Path $QueryFile.FullName -Raw

                                # If this is not the first query in the list, prefix the value list with a comma.
                                if($QuerySequence -ne 1){$Query += ","}
                                
                                # Create the value list for this query, replace all single quotes with two single quotes otherwise the T-SQL insert statement will fail.
                                $Query += "({0}, {1}, {2}, {3}, {4}, '{5}', '{6}', '{7}', 'Not Started', GETDATE(), GETDATE())`r`n" -f $ScenarioID, $BatchID, $ThreadID, $IterationID, $QuerySequence, $QueryFile.FullName, $QueryFile.BaseName, $FileContent.Replace("'", "''")
                            }
                            # Write the queries into the query table for this iteration.
                            $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                        }
                    }
                }

                # Get the list of batches to run.
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Getting the batch list.") -CodeBlock $null
                $Query = "
                    SELECT
                        BatchID
                    FROM dbo.Batch
                    WHERE
                        ScenarioID = {0}
                    ORDER BY BatchID
                " -f $ScenarioID
                $Batches = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows
            }

            # Check to be sure there are batches to run.
            if (($Batches | Measure-Object).Count -gt 0 -and $true -eq $RunScenario) {
                # Loop over the list of batches and run them in series.
                foreach ($Batch in $Batches) {
                    # Initiate the batch level variables.
                    $BatchID = $Batch.BatchID
                    $RunBatch = $false
                    $BatchStartTime = (Get-Date)

                    # Start the current batch.
                    $Query = "
                        UPDATE dbo.Batch
                        SET
                            Status			= 'Running',
                            StartTime 		= GETDATE(),
                            LastUpdateTime 	= GETDATE()
                        WHERE
                            BatchID = {0}
                    " -f $BatchID
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Batch {0} has started." -f $BatchID) -CodeBlock $null
                    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                    # Get the initial set of information from the batch record. 
                    $Query = "
                        DECLARE @BatchID INT = {0}
                        
                        DECLARE @ParentBatchID INT
                        DECLARE @ParentBatchErrorRecordCount INT
                        DECLARE @RunBatch INT
                        
                        /*
                            Notes for later:
                                1. Create logic here to check if the parent batch completed successfully. This would require flagging batch errors on the batch record.
                                2. Instead, maybe look at the existing log to see if there are any errors. If there are, then don't run the batch.

                            SET @ParentBatchID = (SELECT ParentBatchID FROM dbo.Batch WHERE BatchID = @BatchID)

                            IF @ParentBatchID IS NOT NULL
                            BEGIN
                                SET @ParentBatchErrorRecordCount = (SELECT ErrorRecordCount FROM dbo.vwBatch WHERE BatchID = @ParentBatchID)

                                -- A NULL error record count would mean the parent batch run did not complete. A count > 0 would indicate at least 1 error was captured. Do not run this batch.
                                IF (@ParentBatchErrorRecordCount IS NULL OR @ParentBatchErrorRecordCount > 0)
                                SET @RunBatch = 0

                                -- If error record count is 0 that means the parent batch run completed and no errors were captured.
                                ELSE IF (@ParentBatchErrorRecordCount = 0)
                                SET @RunBatch = 1

                                -- Failsafe to not run the batch.
                                ELSE
                                SET @RunBatch = 0
                            END

                            ELSE IF @ParentBatchID IS NULL
                                SET @RunBatch = 1

                            ELSE
                                SET @RunBatch = 0
                        */

                        -- For now, just set the RunBatch value to 1. This means the batch will always run, neven if the parent failed.
                        SET @RunBatch = 1

                        SELECT
                            @RunBatch AS RunBatch,
                            s.WorkspaceName,
                            s.WorkspaceID,
                            s.ItemID,
                            s.ItemType,
                            s.ItemName,
                            s.ItemName AS [Database],
                            s.Server,
                            s.CapacitySubscriptionID,
                            s.CapacityResourceGroupName,
                            s.CapacityRegion,
                            s.CapacityName,
                            s.CapacitySize,
                            s.CapacityID,
                            s.CapacityCUPricePerHour,
                            b.ThreadCount
                        FROM dbo.Batch AS b
                        INNER JOIN dbo.Scenario AS s
                            ON b.ScenarioID = s.ScenarioID
                        WHERE
                            BatchID = @BatchID
                    " -f $BatchID
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Getting information for BatchID {0}." -f $BatchID) -CodeBlock $null
                    $Batch = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows
                    
                    # If the batch returned a true or 1 for being ready to run, set the appropriate variables.
                    if($Batch.RunBatch -eq 1) {
                        # Set the necessary varaibles from the scenario and batch records.
                        $WorkspaceName                  = $Batch.WorkspaceName
                        $WorkspaceID                    = $Batch.WorkspaceID
                        $CapacitySubscriptionID         = $Batch.CapacitySubscriptionID
                        $CapacityResourceGroupName      = $Batch.CapacityResourceGroupName
                        $CapacityName                   = $Batch.CapacityName
                        $CapacitySize                   = $Batch.CapacitySize
                        $CapacityRegion                 = $Batch.CapacityRegion
                        $CapacityCUPricePerHour         = $Batch.CapacityCUPricePerHour
                        $CapacityID                     = $Batch.CapacityID
                        $ItemID                         = $Batch.ItemID
                        $ItemName                       = $Batch.ItemName
                        $ItemType                       = $Batch.ItemType
                        $Server                         = $Batch.Server
                        $Database                       = $Batch.Database
                        $ThreadCount                    = $Batch.ThreadCount

                        <#
                            Notes for later:
                                1. Create a pre-validation script option that will allow a query to be called before the batch will execute.
                                2. This will be part of the automated batch and then move into the batch then it will be gathered and run here.
                                3. Only if the script returns a "true" value will the batch continue to run.
                                4. For now, hard coding $RunBatch = $true
                        #>
                        
                        $RunBatch = $true
                    }
                    # If the batch returned a false or 0 for not being ready to run, set the appropriate variables
                    else {
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The parent batch for batch {0} did not complete successfully." -f $BatchID) -CodeBlock $null
                        $RunBatch = $false
                    }
                
                    if ($true -eq $RunBatch) {
                        # Get the thread list for the batch.
                        $Query = "
                            SELECT
                                t.ThreadID,
                                t.Thread,
                                b.ThreadCount
                            FROM dbo.Thread AS t
                            INNER JOIN dbo.Batch AS b
                                ON t.BatchID = b.BatchID
                            WHERE
                                t.BatchID = {0}
                        " -f $BatchID
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Getting the thread list for batch {0}" -f $BatchID) -CodeBlock $null
                        $Threads = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.tables.Rows

                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} thread(s) will be run in parallel." -f ($Threads | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null

                        $ThreadStatus.Clear()
                        
                        # Run threads in parallel.
                        $ParallelThreads = foreach ($Thread in $Threads) {
                            # Set the job name for the thread.
                            $JobName = "ThreadID_{0}_{1}" -f $Thread.ThreadID, (New-Guid)
                            
                            # Start the job
                            Start-ThreadJob `
                            -Name $JobName `
                            -StreamingHost $Host `
                            -InitializationScript $JobInitializationScript `
                            -ThrottleLimit ($Threads | Measure-Object | Select-Object -ExpandProperty Count) `
                            -ArgumentList ($ScenarioID, $FlightControlServer, $FlightControlDatabase, $BatchID, $Thread.ThreadID, $Thread.Thread, $Thread.ThreadCount, $QueryRetryLimit, $StoreQueryResultsOnQueryRecord) `
                            -ScriptBlock {
                                param(
                                    $ScenarioID,
                                    $FlightControlServer,
                                    $FlightControlDatabase,
                                    $BatchID,
                                    $ThreadID,
                                    $ThreadNumber,
                                    $ThreadCount,
                                    $QueryRetryLimit,
                                    $StoreQueryResultsOnQueryRecord
                                )

                                # Create the local log variable reference for the synchronized hashtable.
                                $LocalLog = $using:Log

                                # Log thread start.
                                $Query = "
                                    DECLARE @ThreadID 	INT = {0}

                                    SELECT
                                        i.IterationID,
                                        s.Server,
                                        s.ItemName AS [Database],
                                        i.Iteration,
                                        b.IterationCount
                                    FROM dbo.Iteration AS i
                                    INNER JOIN dbo.Batch AS b
                                        ON i.BatchID = b.BatchID
                                    INNER JOIN dbo.Scenario AS s
                                        ON b.ScenarioID = s.ScenarioID
                                    WHERE i.ThreadID = @ThreadID
                                    ORDER BY i.Iteration

                                    UPDATE dbo.Thread
                                    SET
                                        Status = 'Running',
                                        StartTime = GETDATE(),
                                        LastUpdateTime = GETDATE()
                                    WHERE ThreadID = @ThreadID
                                " -f $ThreadID
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $null -MessageType "Information" -MessageText ("Thread {0} of {1} has started." -f $ThreadNumber, $ThreadCount) -CodeBlock $null
                                $Iterations = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

                                # Create the local thread varaible reference for the synchronized hashtable.
                                $LocalThreadStatus = $using:ThreadStatus

                                # Add a record indicating that the thread has started.
                                $LocalThreadStatus[$ThreadID] = "Started"

                                # Wait for all the other threads to start before running anything. 
                                do {
                                    Start-Sleep -Milliseconds 500
                                } while (
                                    $LocalThreadStatus.Count -lt $ThreadCount
                                )

                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $null -MessageType "Information" -MessageText ("Thread {0} of {1} detected all other threads have initialized." -f $ThreadNumber, $ThreadCount) -CodeBlock $null

                                # Loop over iterations in series.
                                foreach ($Iteration in $Iterations) {
                                    # Log iteration start.
                                    $Query = "
                                        DECLARE @IterationID INT = {0}

                                        UPDATE dbo.Iteration
                                        SET
                                            Status = 'Running',
                                            StartTime = GETDATE(),
                                            LastUpdateTime = GETDATE()
                                        WHERE
                                            IterationID = @IterationID

                                        SELECT
                                            QueryID,
                                            QuerySequence,
                                            Query
                                        FROM dbo.Query
                                        WHERE
                                            IterationID = @IterationID
                                        ORDER BY QuerySequence
                                    " -f $Iteration.IterationID
                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Iteration {0} of {1} has started." -f $Iteration.Iteration, $Iteration.IterationCount) -CodeBlock $null
                                    $QueryList = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("{0} queries(s) will be run in series." -f ($QueryList | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null
                                    
                                    # Rest the query logging variables.
                                    $QueryCompleteStatements = $null
                                    $QueryLogStatements = $null
                                    
                                    # Loop over each query and run then in series.
                                    foreach($CurrentQuery in $QueryList) {
                                        # Set the variables for the query run loop.
                                        $ContinueLoop = $true
                                        $RetryCount = 1
                                        $RetryLimit = $QueryRetryLimit

                                        do {
                                            try {                                
                                                # Reset the query output variables.
                                                $QueryResults = $null
                                                $QueryCustomLog = $null
                                                $QueryOutput = $null
                                                $QuerySuccessful = $false
                                                
                                                # Run the current query and collect the output for parsing.
                                                $Query = $CurrentQuery.Query
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("Query {0} of {1}" -f $CurrentQuery.QuerySequence, ($QueryList | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null
                                                $QueryOutput = Invoke-FabricSQLCommand -Server $Iteration.Server -Database $Iteration.Database -Query $Query
                                                

                                                # Check the query output for errors. 
                                                if ($QueryOutput.Errors.Count -gt 0) {
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Warning" -MessageText ("An error was found when parsing the query error output.") -CodeBlock $null

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
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("Query execution has ended successfully.") -CodeBlock $null
                                            }
                                            catch {
                                                # If there was an error and the retry limit has been reached raise an error.
                                                if ($RetryCount -ge $RetryLimit) {
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Error" -MessageText ("Query has encountered an error.") -CodeBlock $null
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Error" -MessageText ($_.Exception.Message) -CodeBlock $null
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Error" -MessageText ("Query retry limit has been met ({0} of {1}). Exiting retry loop and terminating iteration." -f $RetryCount, $RetryLimit) -CodeBlock $null
                                                    $ContinueLoop = $false
                                                }
                                                # If there was an error and the retry limit has not been reached raise a warning then retry the query.
                                                else {
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Warning" -MessageText ("Query has encountered an error.") -CodeBlock $null
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Warning" -MessageText ($_.Exception.Message) -CodeBlock $null
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Warning" -MessageText ("Query retry limit has not been met ({0} of {1}). Retry loop will attempt to rerun the query in 10 seconds." -f $RetryCount, $RetryLimit) -CodeBlock $null
                                                    $RetryCount = $RetryCount + 1
                                                    Start-Sleep -Seconds 10
                                                }
                                            }
                                        } while (
                                            $true -eq $ContinueLoop
                                        )

                                        # If the query was successful pase the output for statement ids, custom logs, and query results.
                                        if($QuerySuccessful) {
                                            # Parse the query messages and create records in the query log for each distributed statement id found.
                                            $Query = $null
                                            $DistributedStatementIDCount = 0

                                            # For each message in the query output check to see if it contains a distributed statement id for a query that was executed. If it does, log it. There could be multiple distributed statement ids per query executed by the script (for example a stored procedure may run multiple queries).
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has started.") -CodeBlock $null
                                            foreach ($Message in $QueryOutput.Messages) {
                                                # Parse the message to see if it contains a distributed statement id.
                                                $ParsedMessage = Find-FabricSQLMessage -Message $Message

                                                # If it does contain a distributed statement id, log it to the query log. 
                                                if ($null -ne $ParsedMessage.StatementID) {
                                                    # There is a distributed statement id. Generate the command to write it to the log table.
                                                    $DistributedStatementIDCount += 1

                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("Iteration {0} of {1} has detected a query statement id. The distributed statement id {2} will be written to the query log." -f $Iteration.Iteration, $Iteration.IterationCount, $ParsedMessage.StatementID) -CodeBlock $null
                                                    $QueryLogStatements += "INSERT INTO dbo.QueryLog (ScenarioID, BatchID, ThreadID, IterationID, QueryID, QueryMessage, DistributedStatementID, DistributedRequestID, QueryHash, CreateTime, LastUpdateTime) SELECT {8}, {0}, {1}, {2}, {3}, '{4}', UPPER('{5}'), UPPER('{6}'), '{7}', GETDATE(), GETDATE();`r`n" -f $BatchID, $ThreadID, $Iteration.IterationID, $CurrentQuery.QueryID, $ParsedMessage.Message, $ParsedMessage.StatementID, $ParsedMessage.DistributedRequestID, $ParsedMessage.QueryHash, $ScenarioID
                                                }
                                                else {
                                                    # Do nothing.
                                                }
                                            }
                                        
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has ended.") -CodeBlock $null

                                            # Convert the query output datasets to a JSON string.
                                            if ($true -eq $StoreQueryResultsOnQueryRecord) {
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("The query results will be stored on the iteration log record.") -CodeBlock $null
                                                $QueryResults = $QueryOutput.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json
                                            }

                                            # Check if the last table in the datasets has the custom query log column. If it does, store that value to store it on the iteration log record.
                                            if ($QueryOutput.Dataset.Tables.Count -gt 0) {
                                                if (($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog")) {
                                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -QueryID $CurrentQuery.QueryID -MessageType "Information" -MessageText ("A custom query log was detected and will be stored on the iteration log record.") -CodeBlock $null
                                                    $QueryCustomLog = $QueryOutput.Dataset.Tables[-1].Rows.QueryCustomLog
                                                }
                                            }
                                        }

                                        # Store the full set of query messages, query results, and any custom log on the iteration record.
                                        $QueryCompleteStatements += "
                                        UPDATE dbo.Query
                                            SET
                                                Status				= 'Completed',
                                                StartTime 			= {1},
                                                EndTime 			= {2},
                                                QueryMessage 		= {3},
                                                QueryResults 		= {4},
                                                QueryCustomLog 		= {5},
                                                LastUpdateTime 		= GETDATE()
                                            WHERE QueryID = {0};`r`n
                                        " -f $CurrentQuery.QueryID, $(if($QueryOutput.QueryStartTime -eq "" -or $null -eq $QueryOutput.QueryStartTime){"NULL"} else {"'{0}'" -f $QueryOutput.QueryStartTime}), $(if($QueryOutput.QueryEndTime -eq "" -or $null -eq $QueryOutput.QueryEndTime){"NULL"} else {"'{0}'" -f $QueryOutput.QueryEndTime}), $(if(($QueryOutput.Messages | ConvertTo-JSON) -eq "null" -or $null -eq $QueryOutput.Messages -or ($QueryOutput.Messages | ConvertTo-JSON) -eq ""){"NULL"} else{"'{0}'" -f ($QueryOutput.Messages | ConvertTo-JSON)}), $(if($QueryResults -eq "" -or $null -eq $QueryResults){"NULL"} else{"'{0}'" -f $QueryResults}), $(if($QueryCustomLog -eq "" -or $null -eq $QueryCustomLog){"NULL"} else{"'{0}'" -f $QueryCustomLog})
                                    }

                                    # Update the end of the query records.
                                    if($QueryCompleteStatements.length -gt 0) {
                                        if ($true -eq $StoreQueryResultsOnQueryRecord) {
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the iteration log has started. Query results are being stored on the record which can cause long update times.") -CodeBlock $null
                                        }
                                        else {
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the iteration log has started. Query results are not being stored on the record.") -CodeBlock $null
                                        }
                                        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $QueryCompleteStatements
                                    }
                                    else {
                                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("No data available to update and close out the query records.") -CodeBlock $null
                                    }

                                    # Write the queries to the query log.
                                    if($QueryLogStatements.length -gt 0) {
                                        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $QueryLogStatements
                                    }
                                    else {
                                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("No queries found to log in the query log table.") -CodeBlock $null
                                    }

                                    # Log iteration end.
                                    $Query = "
                                        UPDATE dbo.Iteration
                                        SET		
                                            Status = 'Completed',
                                            EndTime = GETDATE(),
                                            LastUpdateTime = GETDATE()
                                        WHERE
                                            IterationID = {0}" -f $Iteration.IterationID
                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Iteration {0} of {1} has ended." -f $Iteration.Iteration, $Iteration.IterationCount) -CodeBlock $null
                                    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                                }
                            
                                # Log thread end.
                                $Query = "
                                    UPDATE dbo.Thread
                                    SET
                                        Status = 'Completed',
                                        EndTime = GETDATE(),
                                        LastUpdateTime = GETDATE()
                                    WHERE
                                        ThreadID = {0}" -f $ThreadID
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $null -MessageType "Information" -MessageText ("Thread {0} of {1} has ended." -f $ThreadNumber, $ThreadCount) -CodeBlock $null
                                $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                            }
                        }
                        
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting for parallel threads to complete.") -CodeBlock $null

                        # Let the threads run for up to X minutes before stopping them.
                        $WaitForJobsUntil = (Get-Date).AddMinutes($BatchTimeoutInMinutes)
                        $ContinueLoop = $true

                        # Code to write the log to the console while waiting for threads to complete.
                        do {
                            if ((Get-Date) -gt $WaitForJobsUntil) {
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The batch has reached the timeout limit of {0} minutes." -f $BatchTimeoutInMinutes) -CodeBlock $null
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("{0} of {1} thread(s) are running and will be stopped." -f ((Get-Job -State "Running").count), $ThreadCount) -CodeBlock $null
                                foreach ($Job in (Get-Job -State "Running")) {
                                    $Job | Stop-Job
                                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The thread {0} has been stopped." -f $job.Name) -CodeBlock $null
                                }
                            }

                            Start-Sleep -Seconds 10
                        } while (
                            ((Get-Job -State "Running").count -gt 0) -and ($true -eq $ContinueLoop)
                        )

                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("All parallel threads have completed.") -CodeBlock $null

                        # Clean up all the completed jobs.
                        foreach ($Job in (Get-Job -State "Completed")) {
                            $Job | Remove-Job
                        }

                        <#
                            Notes for later: Put a script here to go add an end record to all threads that were terminated
                        #>

                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("All threads have been cleaned up.") -CodeBlock $null
                    }

                    # End the current batch.
                    $Query = "
                        UPDATE dbo.Batch
                        SET
                            Status			= 'Completed',
                            EndTime 		= GETDATE(),
                            LastUpdateTime 	= GETDATE()
                        WHERE
                            BatchID = {0}
                    " -f $BatchID
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Batch {0} has ended." -f $BatchID) -CodeBlock $null
                    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                    Write-Host ""

                }
            } else {
                Write-Host "No batches to process."
            }

            # Update the query log with the details from query insights. 
            if ($true -eq $CollectQueryInsights -and $true -eq $RunScenario) {        
                # Run the command to get the list of distributed statement ids that need to have additional metrics collected from query insights.
                $Query = "
                    SELECT
                        '''' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), q.DistributedStatementID)), ''', ''') + '''' AS QueryInsightsDistributedStatementIDList,
                        '\""' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), q.DistributedStatementID)), '\"", \""') + '\""' AS CapacityMetricsDistributedStatementIDList,
                        COUNT(*) AS DistributedStatementIDCount
                    FROM dbo.QueryLog AS q
                    INNER JOIN dbo.Batch AS b
                        ON q.BatchID = b.BatchID
                    INNER JOIN dbo.Scenario AS s
                        ON b.ScenarioID = s.ScenarioID
                    WHERE
                        s.ScenarioID = {0}
                " -f $ScenarioID
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from query insights.") -CodeBlock $null
                $DistributedStatementIDList = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                # If there are distributed statement ids then continue processing.
                if ($DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount -gt 0) {
                    $Count = $DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount
                    $List = $DistributedStatementIDList.Dataset.Tables.QueryInsightsDistributedStatementIDList

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $Count) -CodeBlock $null

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
                                    session_id AS QueryInsightsSessionID,
                                    login_name AS QueryInsightsLoginName,
                                    CONVERT(NVARCHAR, submit_time, 21) AS QueryInsightsSubmitTime,
                                    CONVERT(NVARCHAR, start_time, 21) AS QueryInsightsStartTime,
                                    CONVERT(NVARCHAR, end_time, 21) AS QueryInsightsEndTime,
                                    total_elapsed_time_ms AS QueryInsightsDurationInMS,
                                    row_count AS QueryInsightsRowCount,
                                    [status] AS QueryInsightsStatus,
                                    result_cache_hit AS QueryInsightsResultCacheHit,
                                    NULLIF([label], '') AS QueryInsightsLabel,
                                    command AS QueryInsightsQueryText
                                FROM queryinsights.exec_requests_history	
                            )
                                
                            SELECT
                                CONCAT(CONVERT(NVARCHAR(MAX), 'UPDATE dbo.QueryLog SET QueryInsightsSessionID = '), QueryInsightsSessionID, ', QueryInsightsLoginName = ''', QueryInsightsLoginName, ''', QueryInsightsSubmitTime = ''', QueryInsightsSubmitTime, ''', QueryInsightsStartTime = ''', QueryInsightsStartTime, ''', QueryInsightsEndTime = ''', QueryInsightsEndTime, ''', QueryInsightsDurationInMS = ', QueryInsightsDurationInMS, ', QueryInsightsRowCount = ', QueryInsightsRowCount, ', QueryInsightsStatus = ''', QueryInsightsStatus, ''', QueryInsightsResultCacheHit = ', QueryInsightsResultCacheHit, ', QueryInsightsLabel = ''', QueryInsightsLabel, ''', QueryInsightsQueryText = ''', QueryInsightsQueryText,' '', LastUpdateTime = GETDATE() WHERE ScenarioID = {0} AND DistributedStatementID = ''', DistributedStatementID, ''';') AS UpdateQueryLogText
                            FROM QueryInsights
                            WHERE DistributedStatementID IN ({1})
                        " -f $ScenarioID, $List
                        $QueryInsightsList = Invoke-FabricSQLCommand -Server $Server -Database $Database -Query $Query
                        
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in query insights is {0} and the current number is {1}." -f $Count, $QueryInsightsList.Dataset.Tables.Rows.Count) -CodeBlock $null
                        
                        # If the query count has not been met and the time limit has not expired, wait for a minute and then check again.
                        if (($QueryInsightsList.Dataset.Tables.Rows.Count -ne $Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking query insights again.") -CodeBlock $null
                            Start-Sleep 60
                        }
                    
                        # If the time limit has expired, stop checking for new queries.
                        if ((Get-Date) -gt $WaitForJobsUntil) {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in query insghts. Therefore, columns in the query log that contain query insights metrics may be incomplete." -f $WaitTimeInMinutesForQueryInsightsData) -CodeBlock $null
                            $ContinueLoop = $false
                        }
                    } while (
                        ($QueryInsightsList.Dataset.Tables.Rows.Count -ne $Count) -and ($true -eq $ContinueLoop)
                    )
                }
                else {
                    $Count = 0
                    $List = ""
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("No distributed statement ids were found in the query log.") -CodeBlock $null
                }
                
                # Convert the query insights results to a string and write the results to the query log.
                if ($QueryInsightsList.Dataset.Tables.Rows.Count -gt 0) {
                    $Query = $QueryInsightsList.Dataset.Tables.Rows.UpdateQueryLogText | Out-String
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has started.") -CodeBlock $null
                    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has ended.") -CodeBlock $null
                }
            }

            # Update the query log with the details from capacity metrics. 
            if ($true -eq $CollectCapacityMetrics -and $true -eq $RunScenario) {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering CU usage from capacity metrics.") -CodeBlock $null
                
                # Run the command to get the list of distributed statement ids that need to have additional metrics collected from capacity metrics.
                $Query = "
                    SELECT
                        '''' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), q.DistributedStatementID)), ''', ''') + '''' AS QueryInsightsDistributedStatementIDList,
                        '\""' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), q.DistributedStatementID)), '\"", \""') + '\""' AS CapacityMetricsDistributedStatementIDList,
                        COUNT(*) AS DistributedStatementIDCount
                    FROM dbo.QueryLog AS q
                    INNER JOIN dbo.Batch AS b
                        ON q.BatchID = b.BatchID
                    INNER JOIN dbo.Scenario AS s
                        ON b.ScenarioID = s.ScenarioID
                    WHERE
                        s.ScenarioID = {0}
                " -f $ScenarioID
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from the query log.") -CodeBlock $null
                $DistributedStatementIDList = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                # If there are distributed statement ids then continue processing.
                if ($DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount -gt 0) {
                    $Count = $DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount
                    $List = $DistributedStatementIDList.Dataset.Tables.QueryInsightsDistributedStatementIDList

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $Count) -CodeBlock $null

                    # Wait for the queries to show up in capacity metrics or for X minutes. Whichever condition is hit first will break the loop.
                    $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForCapacityMetricsData)
                    $ContinueLoop = $true

                    # Look at capacity metrics gather the usage details.
                    do {
                        $CapacityMetrics = Get-FabricCapacityMetrics -CapacityMetricsWorkspace $CapacityMetricsWorkspace -Capacity $CapacityID -OperationIdList $OperationIdList -Date ([datetime]$BatchStartTime).ToString("yyyy-MM-dd 00:00:00")
                        
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in capacity metrics is {0} and the current number is {1}." -f $Count, $CapacityMetrics.Count) -CodeBlock $null

                        # If the query count has not been met and the time limit has not expired, wait for a minute and then check again.
                        if (($CapacityMetrics.Count -ne $Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking capacity metrics again.") -CodeBlock $null
                            Start-Sleep 60
                        }

                        # If the time limit has expired, stop checking for new queries.
                        if ((Get-Date) -gt $WaitForJobsUntil) {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in capacity metrics. Therefore, columns in the query log that contain capacity metrics may be incomplete." -f $WaitTimeInMinutesForCapacityMetricsData) -CodeBlock $null
                            $ContinueLoop = $false
                        }
                    }
                    while (
                        ($CapacityMetrics.Count -ne $Count) -and ($true -eq $ContinueLoop)
                    )
                }
                else {
                    $Count = 0
                    $List = ""
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("No distributed statement ids were found in the query log.") -CodeBlock $null
                }
                
                # Convert the capacity metrics results to a string and write the results to the query log.
                if ($CapacityMetrics.Count -gt 0) {
                    $Query = $null

                    # Create a single batch of update statements to run together. 
                    foreach ($Item in $CapacityMetrics) {
                        $Query += "
                            UPDATE dbo.QueryLog
                            SET
                                CapacityMetricsStartTime = '{2}', 
                                CapacityMetricsEndTime = '{3}', 
                                CapacityMetricsCUs = {4}, 
                                CapacityMetricsQueryPrice = CONVERT(DECIMAL(18,6), ((SELECT CONVERT(DECIMAL(18,6), CapacityCUPricePerHour) FROM dbo.Scenario WHERE ScenarioID = {6}) / 3600.) * {4}),
                                CapacityMetricsDurationInSeconds = {5},
                                LastUpdateTime = GETDATE()
                            WHERE
                                ScenarioID = {0}
                                AND DistributedStatementID = '{1}';`r`n
                        "  -f $ScenarioID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration, $ScenarioID
                    }

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in capacity metrics has started.") -CodeBlock $null
                    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in capacity metrics has ended.") -CodeBlock $null
                }
            }

            # Convert the log to JSON and store it in a variable to write it to the SQL table.
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the log for scenario {0}." -f $ScenarioID) -CodeBlock $null
            $LocalLog = ($Log.Values | ConvertTo-JSON).replace("'", "\u0027")

            # Run the command to update the scenario table log field.
            $Query = "
                UPDATE dbo.Scenario
                SET
                    EndTime = GETDATE(),
                    Status = 'Completed',
                    HasError = {2},
                    HasWarning = {3},
                    ScenarioLog = REPLACE('{1}', '\u0027', ''''),
                    LastUpdateTime 	= GETDATE()
                WHERE ScenarioID = {0}
            " -f $ScenarioID, $LocalLog, $(if($LocalLog.Contains('"MessageType": "Error"')) {1} else {0}), $(if($LocalLog.Contains('"MessageType": "Warning"')) {1} else {0})
            $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
        }
    }
    else {
        Write-Host "No scenarios to process."
    }
    Write-Host ""
}

<#
    Notes for later:
        1. Consider code to pause the capacity if no other batches are using it to save cost. 
        2. Add a field to the batch table that specifies the compute engine. It could be Fabric DW, Lakehouse SQL Endpoint, etc. But if the compute is not Fabric DW or SQL Endpoint then we shoul not attempt capture the Fabric ids, capacity information etc. Perhaps that gets stored in a JSON field in the future so it can store whatever is needed for any compute engine in Fabric, Databricsk, Azure SQL, etc.
        3. Create a generic stored procedure for people to populate their own test scripts. Maybe make a powershell script that will read SQL files into the tables otherwise they can specify their own scripts in PowerShell to be populated.
#>