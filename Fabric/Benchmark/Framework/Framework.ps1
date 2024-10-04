Clear-Host

#param (
    <#*****     Fabric Workspace Filter     *****#>
    [string]$WorkspaceName

    <#*****     Flight Control Database     *****#>
    [string]$FlightControlServer = 'scbradlsql01.database.windows.net'
    [string]$FlightControlDatabase = 'FlightControl_vNextNext'

    <#*****     Capacity Metrics     *****#>
    [string]$CapacityMetricsDatasetID = '287f17e3-a624-4663-9dd8-c4f521edced2'

    <#*****     Log Storage Location     *****#>
    [string]$BatchLogFolder = "C:\Logging\Batch"

    <#*****     Runtime Variables     *****#>
    [boolean]$GenerateNewScenarios                      = $true   <#  Default: $false  #>
    [boolean]$BuildOutScenarios                         = $true 
    [boolean]$GetInformationFromAPICalls                = $true
    [boolean]$CollectQueryInsights                      = $true    <#  Default: $true  #>
    [boolean]$CollectCapacityMetrics                    = $true    <#  Default: $true  #>
    [boolean]$PauseOnCapacitySizeChange                 = $false   <#  Default: $false  #>
    [boolean]$StoreQueryResultsOnIterationRecord        = $false   <#  Default: $false  #>
    [int32]$BatchTimeoutInMinutes                       = 120      <#  Default: 120 minutes  #>
    [int32]$QueryRetryLimit                             = 2        <#  Default: 1 -> The batch will not retry on failure.  #>
    [int32]$WaitTimeInMinutesForQueryInsightsData       = 15       <#  Default: 10  minutes  #>
    [int32]$WaitTimeInMinutesForCapacityMetricsData     = 15       <#  Default: 10  minutes  #>
    [int32]$WaitTimeInSecondsAfterCapacitySkuChange     = 300      <#  Default: 5 minutes -> 300 seconds  #>
    [int32]$WaitTimeInSecondsAfterCapacityResume        = 60       <#  Default: 1 minute  -> 60  seconds  #>
    [int32]$WaitTimeInSecondsToRefreshConsole           = 10       <#  Default: 1 minute  -> 10  seconds  #>
#)

<#*****     Job Initialization Script     *****#>
$JobInitializationScript = {
    # Get the Fabric functions.
    (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bradleyschacht/resources/refs/heads/main/Fabric/PowerShell/Fabric%20Functions.ps1") | Invoke-Expression

    function Add-LogEntry {
        param (
            $ScenarioID,    
            $BatchID,
            $ThreadID,
            $IterationID,
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
            "MessageType"           = $MessageType
            "MessageTime"           = $MessageTime
            "MessageText"           = $MessageText
            "CodeBlock"             = $CodeBlock
        }

        # Add the message to the log or update existing records.
        $LocalLog[$LogKey] = $Message

        # Write the message to the console.
        if($MessageType -eq "Error") {
            Write-Host ("{0} | {1} | ScenarioID {2} | BatchID {3} | ThreadID {4} | IterationID {5} | {6} | {7}" -f $MessageTime, $MessageType, $ScenarioID, $BatchID, $ThreadID, $IterationID, $MessageText, $CodeBlock) -ForegroundColor Red
        }
        else {
            Write-Host ("{0} | {1} | ScenarioID {2} | BatchID {3} | ThreadID {4} | IterationID {5} | {6} | {7}" -f $MessageTime, $MessageType, $ScenarioID, $BatchID, $ThreadID, $IterationID, $MessageText, $CodeBlock)
        }

        # Write the message to the log.
        # Write-Output ($Message | ConvertTo-JSON | Out-String) | Out-File $LogFilePath -Append
    }
}

# Store the starting time in a variable.
$ScriptStartTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")

# Write out the variables for the run.
Write-Host "*************************************************************************************"
Write-Host ""
Write-Host ("{0}: {1}" -f "StartTime", $ScriptStartTime)
Write-Host ""
Write-Host "***  Workspace Filter  ***"
Write-Host ("{0}: {1}" -f "WorkspaceName", $WorkspaceName)
Write-Host ""
Write-Host "***  Flight Control Database  ***"
Write-Host ("{0}: {1}" -f "FlightControlServer", $FlightControlServer)
Write-Host ("{0}: {1}" -f "FlightControlDatabase", $FlightControlDatabase)
Write-Host ""
Write-Host "***  Capacity Metrics  ***"
Write-Host ("{0}: {1}" -f "CapacityMetricsDatasetID", $CapacityMetricsDatasetID)
Write-Host ""
Write-Host "***  Log Storage Location  ***"
Write-Host ("{0}: {1}" -f "BatchLogFolder", $BatchLogFolder)
Write-Host ("{0}: {1}" -f "ThreadLogFolder", $ThreadLogFolder)
Write-Host ("{0}: {1}" -f "IterationLogFolder", $IterationLogFolder)
Write-Host ""
Write-Host "***  Runtime Variables  ***"
Write-Host ("{0}: {1}" -f "GenerateNewBatches", $GenerateNewBatches)
Write-Host ("{0}: {1}" -f "CollectQueryInsights", $CollectQueryInsights)
Write-Host ("{0}: {1}" -f "CollectCapacityMetrics", $CollectCapacityMetrics)
Write-Host ("{0}: {1}" -f "PauseOnCapacitySizeChange", $PauseOnCapacitySizeChange)
Write-Host ("{0}: {1}" -f "StoreQueryResultsOnIterationRecord", $StoreQueryResultsOnIterationRecord)
Write-Host ("{0}: {1}" -f "BatchTimeoutInMinutes", $BatchTimeoutInMinutes)
Write-Host ("{0}: {1}" -f "QueryRetryLimit", $QueryRetryLimit)
Write-Host ("{0}: {1}" -f "WaitTimeInMinutesForQueryInsightsData", $WaitTimeInMinutesForQueryInsightsData)
Write-Host ("{0}: {1}" -f "WaitTimeInMinutesForCapacityMetricsData", $WaitTimeInMinutesForCapacityMetricsData)
Write-Host ("{0}: {1}" -f "WaitTimeInSecondsAfterCapacitySkuChange", $WaitTimeInSecondsAfterCapacitySkuChange)
Write-Host ("{0}: {1}" -f "WaitTimeInSecondsAfterCapacityResume", $WaitTimeInSecondsAfterCapacityResume)
Write-Host ("{0}: {1}" -f "WaitTimeInSecondsToRefreshConsole", $WaitTimeInSecondsToRefreshConsole)
Write-Host ""
Write-Host "*************************************************************************************"
Write-Host ""
Write-Host ""





# Load all the functions.
Invoke-Expression ($JobInitializationScript | Out-String)



# Generate new scenarios.
if ($true -eq $GenerateNewScenarios) {
    Write-Host "Generating scenarios."
    #$Query = "EXEC dbo.Create_Scenario @WorkspaceName = '{0}'" -f $WorkspaceName
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
        
        
        DECLARE Scenario CURSOR FOR
            SELECT
                ScenarioID, ScenarioName, WorkspaceName, ItemName, CapacitySubscriptionID, CapacityResourceGroupName, CapacityName, CapacitySize, Dataset, DataSize, DataStorage
            FROM automation.Scenario
            WHERE 
                (
                    (
                        CASE WHEN @WorkspaceName = '' OR @WorkspaceName IS NULL THEN 1 ELSE 0 END = 1
                    )
                    OR
                    (
                        CASE WHEN @WorkspaceName != '' THEN 1 ELSE 0 END = 1
                        AND WorkspaceName = @WorkspaceName
                    )
                )
                AND IsActive = 1
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
    " -f $WorkspaceName
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
	FROM dbo.Scenario
	WHERE
		StartTime IS NULL
		AND WorkspaceName = @WorkspaceName
	ORDER BY
		ScenarioID" -f $WorkspaceName
$Scenarios = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

if (($Scenarios | Measure-Object).Count -gt 0){
    # Loop over the list of scenarios and run them in series.
    foreach($Scenario in $Scenarios){

        $ScenarioID = $Scenario.ScenarioID

        # Create the synchronized hashtable to store the log, shared functions, and thread status.
        $Log = [Hashtable]::Synchronized(@{})
        $ThreadStatus = [Hashtable]::Synchronized(@{})

        $Log.Clear()
        # This is moved to the beginning of the batch > $ThreadStatus.Clear()

        # Initiate the scenario level log.
        $LogFilePath = (Join-Path -Path $BatchLogFolder -ChildPath ("B{0} - {1}.txt" -f $BatchID, (Get-Date).ToUniversalTime().ToString("yyyy_MM_ddTHH_mm_ss_ffff")))    

        # Create the local log variable reference.
        $LocalLog = $Log

        # Start the current scenario.
        $Query = "UPDATE dbo.Scenario SET Status = 'Running', StartTime = GETDATE(), LastUpdateTime = GETDATE() WHERE ScenarioID = {0}" -f $ScenarioID
        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Scenario {0} has started." -f $ScenarioID) -CodeBlock $null
        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
        
        if($GetInformationFromAPICalls){
            # Update the necessary fields from the scenario record.
            $WorkspaceName                  = $Scenario.WorkspaceName
            $CapacitySubscriptionID         = $Scenario.CapacitySubscriptionID
            $CapacityResourceGroupName      = $Scenario.CapacityResourceGroupName
            $CapacityName                   = $Scenario.CapacityName
            $CapacitySize                   = $Scenario.CapacitySize
            $ItemName                       = $Scenario.ItemName
            $Database                       = $Scenario.ItemName
            
            # Get the workspace id.
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to gather workspace id.") -CodeBlock $null
            $WorkspaceID = (Get-FabricWorkspace -Workspace $WorkspaceName).id

            # Get the capacity id.
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to capacity id.") -CodeBlock $null
            $CapacityID = (Get-FabricCapacity -Location "Fabric" -Capacity $Scenario.CapacityName).id

            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to get capacity region.") -CodeBlock $null
            $CapacityRegion = (Get-FabricCapacity -Location "Azure" -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName).location
            
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Calling API to get capacity CU price per hour.") -CodeBlock $null
            $CapacityCUPricePerHour = Get-FabricCUPricePerHour -Region $CapacityRegion
            
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



            # Update the scenario record with the information gathered from the API calls.
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
                WHERE ScenarioID = {7}" -f $WorkspaceID, $ItemID, $ItemType, $Server, $CapacityCUPricePerHour, $CapacityRegion, $CapacityID, $ScenarioID
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Scenario lookup values have been updated.") -CodeBlock $null
            $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query


            # Write the parameters to the console and the log.
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Workspace:                 {0}" -f $WorkspaceName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("WorkspaceID:               {0}" -f $WorkspaceID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ItemID:                    {0}" -f $ItemID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ItemName:                  {0}" -f $ItemName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ItemType:                  {0}" -f $ItemType) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Server:                    {0}" -f $Server) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Database:                  {0}" -f $Database) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacitySubscriptionID:    {0}" -f $CapacitySubscriptionID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityResourceGroupName: {0}" -f $CapacityResourceGroupName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityName:              {0}" -f $CapacityName) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacitySize:              {0}" -f $CapacitySize) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityRegion:            {0}" -f $CapacityRegion) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityCUPricePerHour:    {0}" -f $CapacityCUPricePerHour) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("CapacityID:                {0}" -f $CapacityID) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("ThreadCount:               {0}" -f $ThreadCount) -CodeBlock $null
             
            

            <#**********     Scale capacity start     **********#>
            # Get the capacity's current state and SKU.
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Assigning capacity to the workspace.") -CodeBlock $null
            $null = Set-FabricWorkspaceCapacity -Workspace $WorkspaceID -Capacity $CapacityID
            
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Checking capacity SKU and status.") -CodeBlock $null
            $CapacityCurrent = Get-FabricCapacity -Location "Azure" -SubscriptionID $CapacitySubscriptionID -ResourceGroupName $CapacityResourceGroupName -Capacity $CapacityName
            
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity current state: {0}" -f $CapacityCurrent.properties.state) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity current SKU:   {0}" -f $CapacityCurrent.sku.name) -CodeBlock $null
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity expected SKU:  {0}" -f $CapacitySize) -CodeBlock $null
    
            # Check if the current vs. expected SKUs match. If they don't, scale the capacity.
            if ($CapacityCurrent.sku.name -ne $CapacitySize) {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Capacity SKUs do not match.") -CodeBlock $null
                
                # Pause the capacity if it is running so that the current activity is cleared.
                if (($CapacityCurrent.properties.state -ne "Paused") -and ($true -eq $PauseOnCapacitySizeChange)) {
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
            <#**********     Scale capacity end     **********#>
    
            <#**********     Make sure the SQL endpoint is up and running start     **********#>
            # Set the variables for the SQL endpoint check loop.
            $RetryLimit         = 2
            $RetryCount         = 1
            $SQLEndpointActive  = $false
    
            do {
                try {
                    # Run a query against the database to see if it can connect and return a result.
                    $null = Invoke-FabricSQLCommand -Server $Server -Database $Database -Query "SELECT * FROM sys.databases"
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("SQL endpoint is online and responding.") -CodeBlock $null
                    
                    # Set the varaibles to indicate the batch should be run and the SQL endpoint check loop is complete.
                    $RunBatch           = $true
                    $SQLEndpointActive  = $true
                }
                catch {
                    $RunBatch   = $false
                    $RetryCount = $RetryCount + 1
                    if ($RetryCount -gt $RetryLimit) {
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1)) -CodeBlock $null
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ($_.Exception.Message) -CodeBlock $null
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("SQL endpoint check retry limit has been met. Terminating the SQL endpoint check and the batch.") -CodeBlock $null
                    }
                    else {
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("SQL endpoint check number {0} encountered an error." -f ($RetryCount - 1)) -CodeBlock $null
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ($_.Exception.Message) -CodeBlock $null
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("SQL endpoint check retry limit has not been met. Rechecking the SQL endpoint in 60 seconds.") -CodeBlock $null
                        Start-Sleep -Seconds 60
                    }     
                }
            } until (
                ($true -eq $SQLEndpointActive) -or ($RetryCount -gt $RetryLimit)
            )
            <#**********     Make sure the SQL endpoint is up and running end     **********#>



        }

        if($BuildOutScenarios) {
            # Build out the scenario (Batches, Threads, Iterations, and Queries).
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Building out the scenario.") -CodeBlock $null
            $Query = "
                SELECT
                    BatchID,
                    IterationCount,
                    BatchFolder
                FROM dbo.Batch
                WHERE
                    ScenarioID = {0}
                ORDER BY
                    BatchID" -f $ScenarioID
            $Batches = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

            foreach($Batch in $Batches){
                $BatchID = $Batch.BatchID
                $BatchFolder = $Batch.BatchFolder
                $IterationCount = $Batch.IterationCount

                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Generating threads for Batch {0}." -f $BatchID) -CodeBlock $null
                
                $ThreadList = Get-ChildItem -Path $BatchFolder -Directory | Sort-Object Name

                $Query = "UPDATE dbo.Batch SET ThreadCount = {0}, BatchName = '{1}', LastUpdateTime = GETDATE() WHERE BatchID = {2}" -f $ThreadList.Count, (Split-Path -Path $BatchFolder -Leaf), $BatchID
                $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                $ThreadNumber = 0
                foreach($Thread in $ThreadList){
                    $ThreadNumber ++

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Generating Thread {0}." -f $ThreadNumber) -CodeBlock $null

                    # Get the query list for this thread.
                    $QueryList = Get-ChildItem -Path $Thread.FullName -File | Sort-Object Name

                    $Query = "INSERT INTO dbo.Thread (ScenarioID, BatchID, Thread, Status, ThreadName, ThreadFolder, CountOfQueries, CreateTime, LastUpdateTime) VALUES ({5}, {0}, {1}, 'Not Started', '{2}', '{3}', {4}, GETDATE(), GETDATE()); SELECT SCOPE_IDENTITY() AS ThreadID;" -f $BatchID, $ThreadNumber, $Thread.Name, $Thread.FullName, $QueryList.Count, $ScenarioID
                    $ThreadID = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows.ThreadID

                    foreach($Iteration in 1..$IterationCount){
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Generating Iteration {0}." -f $Iteration) -CodeBlock $null
                        
                        $Query = "INSERT INTO dbo.Iteration (ScenarioID, BatchID, ThreadID, Iteration, Status, CreateTime, LastUpdateTime) VALUES({3}, {0}, {1}, {2}, 'Not Started', GETDATE(), GETDATE()); SELECT SCOPE_IDENTITY() AS IterationID;" -f $BatchID, $ThreadID, $Iteration, $ScenarioID
                        $IterationID = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows.IterationID

                        $QuerySequence = 0
                        $Query = "INSERT INTO dbo.Query(ScenarioID, BatchID, ThreadID, IterationID, QuerySequence, QueryFile, QueryName, Query, Status, CreateTime, LastUpdateTime) `r`nVALUES`r`n"
                        foreach($QueryFile in $QueryList){
                            $QuerySequence ++
                            $FileContent = ""
                            $FileContent = Get-Content -Path $QueryFile.FullName -Raw

                            if($QuerySequence -ne 1){$Query += ","}
                            $Query += "({0}, {1}, {2}, {3}, {4}, '{5}', '{6}', '{7}', 'Not Started', GETDATE(), GETDATE())`r`n" -f $ScenarioID, $BatchID, $ThreadID, $IterationID, $QuerySequence, $QueryFile.FullName, $QueryFile.BaseName, $FileContent.Replace("'", "''")
                        }
                        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                    }
                }
            }
        }
    
        ##################################################################################
        # Now that the scenario is built, go ahead and run through it.

        # Get the list of batches to run.
        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Getting the batch list.") -CodeBlock $null
        $Query = "
            SELECT
                BatchID
            FROM dbo.Batch
            WHERE
                ScenarioID = {0}
            ORDER BY BatchID" -f $ScenarioID
        $Batches = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows
        
        # Check to be sure there are batches to run.
        if (($Batches | Measure-Object).Count -gt 0 -and $true -eq $RunBatch) {
            # Loop over the list of batches and run them in series.
            foreach ($Batch in $Batches) {
                $ErrorCount = -1

                $BatchID = $Batch.BatchID

                # Initiate the batch level variables.
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
                        BatchID = {0}" -f $BatchID
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Batch {0} has started." -f $BatchID) -CodeBlock $null
                $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                <###########################################################################################################################################################################################>
                # Get the initial set of information from the batch record. 
                $Query = "
                    DECLARE @BatchID INT = {0}
                    
                    DECLARE @ParentBatchID INT
                    DECLARE @ParentBatchErrorRecordCount INT
                    DECLARE @RunBatch INT
                    /*
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
                        BatchID = @BatchID" -f $BatchID
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Getting information for BatchID {0}." -f $BatchID) -CodeBlock $null
                $Batch = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows
                <###########################################################################################################################################################################################>

                
                if($Batch.RunBatch -eq 1) {
                    # Update the necessary fields from the batch record.
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
                            5. The rest of this comment was the original code, but I want to change the logic to make this more flexible.
            
                        # Determine if the batch should run or not. If a prior Power Run has not completed successfully, the concurrency run should not run.
                        $Query = "EXEC dbo.Get_BatchRunCheck @BatchID = {0}, @StartTime = '{1}'" -f $BatchID, $StartTime
                        $BatchStatus = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.tables.Rows
            
                        if ($BatchStatus.RunBatch -eq 1) {
                            $RunBatch = $true
                            Write-Log -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The batch run check has ended successfully.") -CodeBlock $null
                        }
                        else {
                            $RunBatch = $false
                            Write-Log -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The batch run check indicated a corresponding power run has not completed successfully.") -CodeBlock $null
                        }
                    #>
                    $RunBatch = $true
                }
                else {
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The parent batch for batch {0} did not complete successfully." -f $BatchID) -CodeBlock $null
                    $RunBatch = $false
                }










            
                <#**********     Batch start     **********#>
                if ($true -eq $RunBatch) {
                    <#**********     Threads start     **********#>
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
                            t.BatchID = {0}" -f $BatchID
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Getting the thread list for batch {0}" -f $BatchID) -CodeBlock $null
                    $Threads = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.tables.Rows

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} thread(s) will be run in parallel." -f ($Threads | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null

                    $ThreadStatus.Clear()
                    
                    # Run threads in parallel.
                    $ParallelThreads = foreach ($Thread in $Threads) {
                        $JobName = "ThreadID_{0}_{1}" -f $Thread.ThreadID, (New-Guid)
                        
                        Start-ThreadJob `
                        -Name $JobName `
                        -StreamingHost $Host `
                        -InitializationScript $JobInitializationScript `
                        -ThrottleLimit ($Threads | Measure-Object | Select-Object -ExpandProperty Count) `
                        -ArgumentList ($ScenarioID, $FlightControlServer, $FlightControlDatabase, $BatchID, $Thread.ThreadID, $Thread.Thread, $Thread.ThreadCount, $QueryRetryLimit, $StoreQueryResultsOnIterationRecord) `
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
                                $StoreQueryResultsOnIterationRecord
                            )

                            # Create the local log variable reference.
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
                                WHERE ThreadID = @ThreadID" -f $ThreadID
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $null -MessageType "Information" -MessageText ("Thread {0} of {1} has started." -f $ThreadNumber, $ThreadCount) -CodeBlock $null
                            $Iterations = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

                            # Create the local thread varaible reference.
                            $LocalThreadStatus = $using:ThreadStatus

                            # Write that the thread has started.
                            $LocalThreadStatus[$ThreadID] = "Started"

                            # Wait for all the other threads to start before running anything. 
                            do {
                                Start-Sleep -Milliseconds 500
                            } while (
                                $LocalThreadStatus.Count -lt $ThreadCount
                            )

                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $null -MessageType "Information" -MessageText ("Thread {0} of {1} detected all other threads have initialized." -f $ThreadNumber, $ThreadCount) -CodeBlock $null

                            <#**********     Iterations start     **********#>
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
                                    ORDER BY QuerySequence" -f $Iteration.IterationID
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Iteration {0} of {1} has started." -f $Iteration.Iteration, $Iteration.IterationCount) -CodeBlock $null
                                $QueryList = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("{0} queries(s) will be run in series." -f ($QueryList | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null

                                
                                
                                $QueryCompleteStatements = $null
                                $QueryLogStatements = $null
                                
                                
                                
                                foreach($CurrentQuery in $QueryList) {
                                    # Set the variables for the iteration run loop.
                                    $ContinueLoop       = $true
                                    $RetryCount         = 1
                                    $RetryLimit         = $QueryRetryLimit

                                    do {
                                        try {                                
                                            $QueryResults = $null
                                            $QueryCustomLog = $null
                                    
                                            # $Query = "
                                            #     UPDATE dbo.Query
                                            #     SET
                                            #         Status = 'Running',
                                            #         LastUpdateTime = GETDATE()
                                            #     WHERE
                                            #         QueryID = {0}" -f $CurrentQuery.QueryID
                                            # $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                                            
                                            $Query = $CurrentQuery.Query
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Query {0} of {1}" -f $CurrentQuery.QuerySequence, ($QueryList | Measure-Object | Select-Object -ExpandProperty Count)) -CodeBlock $null
                                            $QueryOutput = Invoke-FabricSQLCommand -Server $Iteration.Server -Database $Iteration.Database -Query $Query
                                            

                                            if ($QueryOutput.Errors.Count -gt 0) {
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Error" -MessageText ("An error was found when parsing the query error output.") -CodeBlock $null

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
                                            Get-Job | Stop-Job
                                            $ContinueLoop = $false

                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Query execution has ended successfully.") -CodeBlock $null
                                        }
                                        catch {
                                            
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Error" -MessageText ("Query has encountered an error.") -CodeBlock $null
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Error" -MessageText ($_.Exception.Message) -CodeBlock $null

                                            if ($RetryCount -ge $RetryLimit) {
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Error" -MessageText ("Query retry limit has been met ({0} of {1}). Exiting retry loop and terminating iteration." -f $RetryCount, $RetryLimit) -CodeBlock $null
                                                $ContinueLoop = $false
                                            }
                                            else {
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Error" -MessageText ("Query retry limit has not been met ({0} of {1}). Retry loop will attempt to rerun the query in 10 seconds." -f $RetryCount, $RetryLimit) -CodeBlock $null
                                                $RetryCount = $RetryCount + 1
                                                Start-Sleep -Seconds 10
                                            }
                                        }

                                        # Parse the query messages and create records in the query log for each distributed statement id found.
                                        $Query = $null
                                        $DistributedStatementIDCount = 0

                                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has started.") -CodeBlock $null
                                        foreach ($Message in $QueryOutput.Messages) {
                                            $ParsedMessage = Find-FabricSQLMessage -Message $Message

                                            if ($null -ne $ParsedMessage.StatementID) {
                                                # There is a distributed statement id. Generate the command to write it to the log table.
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Iteration {0} of {1} has detected a query statement id. The distributed statement id {2} will be written to the query log." -f $Iteration.Iteration, $Iteration.IterationCount, $ParsedMessage.StatementID) -CodeBlock $null
                                                $DistributedStatementIDCount += 1
                                                #$Query += "EXEC dbo.Create_QueryLog @BatchID = {0}, @ThreadID = {1}, @IterationID = {2}, @QueryID = {3}, @QueryMessage = '{4}', @DistributedStatementID = '{5}', @DistributedRequestID = '{6}', @QueryHash =  '{7}';`r`n" -f $BatchID, $ThreadID, $Iteration.IterationID, $CurrentQuery.QueryID, $ParsedMessage.Message, $ParsedMessage.StatementID, $ParsedMessage.DistributedRequestID, $ParsedMessage.QueryHash
                                                #$Query += "INSERT INTO dbo.QueryLog (ScenarioID, BatchID, ThreadID, IterationID, QueryID, QueryMessage, DistributedStatementID, DistributedRequestID, QueryHash, CreateTime, LastUpdateTime) SELECT {8}, {0}, {1}, {2}, {3}, '{4}', UPPER('{5}'), UPPER('{6}'), '{7}', GETDATE(), GETDATE();`r`n" -f $BatchID, $ThreadID, $Iteration.IterationID, $CurrentQuery.QueryID, $ParsedMessage.Message, $ParsedMessage.StatementID, $ParsedMessage.DistributedRequestID, $ParsedMessage.QueryHash, $ScenarioID
                                                $QueryLogStatements += "INSERT INTO dbo.QueryLog (ScenarioID, BatchID, ThreadID, IterationID, QueryID, QueryMessage, DistributedStatementID, DistributedRequestID, QueryHash, CreateTime, LastUpdateTime) SELECT {8}, {0}, {1}, {2}, {3}, '{4}', UPPER('{5}'), UPPER('{6}'), '{7}', GETDATE(), GETDATE();`r`n" -f $BatchID, $ThreadID, $Iteration.IterationID, $CurrentQuery.QueryID, $ParsedMessage.Message, $ParsedMessage.StatementID, $ParsedMessage.DistributedRequestID, $ParsedMessage.QueryHash, $ScenarioID
                                            }
                                            else {
                                                # Do nothing.
                                            }
                                        }
                                        
                                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Seaching the message output to look for distributed statement ids has ended.") -CodeBlock $null

                                        # if ($DistributedStatementIDCount -gt 0) {
                                        #     # Write the distributed statement ids to the query log table.
                                        #     $null = Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("Creating query log records for {0} distributed statement ids." -f $DistributedStatementIDCount) -CodeBlock $null
                                        #     $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                                            
                                        # }

                                        # Convert the query output datasets to a JSON string.
                                        if ($true -eq $StoreQueryResultsOnIterationRecord) {
                                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("The query results will be stored on the iteration log record.") -CodeBlock $null
                                            $QueryResults = $QueryOutput.Dataset.Tables.Rows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json
                                        }

                                        # Check if the last table in the datasets has the custom query log column. If it does, store that value to store it on the iteration log record.
                                        if ($QueryOutput.Dataset.Tables.Count -gt 0) {
                                            if (($QueryOutput.Dataset.Tables[-1].Columns.ColumnName).Contains("QueryCustomLog")) {
                                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $ThreadID -IterationID $Iteration.IterationID -MessageType "Information" -MessageText ("A custom query log was detected and will be stored on the iteration log record.") -CodeBlock $null
                                                $QueryCustomLog = $QueryOutput.Dataset.Tables[-1].Rows.QueryCustomLog
                                            }
                                        }

                                        # Store the full set of query messages, query results, and any custom log on the iteration record.
                                        # $Query = "
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
                                            WHERE QueryID = {0};`r`n" -f $CurrentQuery.QueryID, $(if($QueryOutput.QueryStartTime -eq "" -or $null -eq $QueryOutput.QueryStartTime){"NULL"} else {"'{0}'" -f $QueryOutput.QueryStartTime}), $(if($QueryOutput.QueryEndTime -eq "" -or $null -eq $QueryOutput.QueryEndTime){"NULL"} else {"'{0}'" -f $QueryOutput.QueryEndTime}), $(if(($QueryOutput.Messages | ConvertTo-JSON) -eq "null" -or $null -eq $QueryOutput.Messages -or ($QueryOutput.Messages | ConvertTo-JSON) -eq ""){"NULL"} else{"'{0}'" -f ($QueryOutput.Messages | ConvertTo-JSON)}), $(if($QueryResults -eq "" -or $null -eq $QueryResults){"NULL"} else{"'{0}'" -f $QueryResults}), $(if($QueryCustomLog -eq "" -or $null -eq $QueryCustomLog){"NULL"} else{"'{0}'" -f $QueryCustomLog})
                                        # if ($true -eq $StoreQueryResultsOnIterationRecord) {
                                        #     $null = Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the iteration log has started. Query results are being stored on the record which can cause long update times.") -CodeBlock $null
                                        # }
                                        # else {
                                        #     $null = Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the iteration log has started. Query results are not being stored on the record.") -CodeBlock $null
                                        # }
                                        # (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query)
                                    } while (
                                        $true -eq $ContinueLoop
                                    )
                                }



                                # Update the end of the query records.
                                if($QueryCompleteStatements.length -gt 0){
                                    if ($true -eq $StoreQueryResultsOnIterationRecord) {
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
                                if($QueryLogStatements.length -gt 0){
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

                    # Let the threads run for up to 2 hours before stopping them.
                    $WaitForJobsUntil = (Get-Date).AddMinutes($BatchTimeoutInMinutes)
                    $ContinueLoop = $true

                    # Code to write the log to the console while waiting for threads to complete.
                    do {
                        if ((Get-Date) -gt $WaitForJobsUntil) {
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The batch has reached the timeout limit of {0} minutes." -f $BatchTimeoutInMinutes) -CodeBlock $null
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("{0} of {1} thread(s) are running and will be stopped." -f ((Get-Job -State "Running").count), $ThreadCount) -CodeBlock $null
                            foreach ($Job in (Get-Job -State "Running")) {
                                $job | Stop-Job
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Error" -MessageText ("The thread {0} has been stopped." -f $job.Name) -CodeBlock $null
                            }
                        }

                        Start-Sleep -Seconds $WaitTimeInSecondsToRefreshConsole
                    } while (
                        ((Get-Job -State "Running").count -gt 0) -and ($true -eq $ContinueLoop)
                    )

                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("All parallel threads have completed.") -CodeBlock $null

                    foreach ($Job in (Get-Job -State "Completed")) {
                        $job | Remove-Job
                    }

                    <#
                        Notes for later: Put a stored procedure here to go add an end record to all threads that were terminated
                    #>
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("All threads have been cleaned up.") -CodeBlock $null
                }


                <#
                # Update the query log with the details from query insights. 
                if ($true -eq $CollectQueryInsights) {        
                    # Run the command to get the list of distributed statement ids that need to have additional metrics collected from query insights.
                    $Query = "
                        SELECT
                            '''' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), DistributedStatementID)), ''', ''') + '''' AS QueryInsightsDistributedStatementIDList,
                            '\""' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), DistributedStatementID)), '\"", \""') + '\""' AS CapacityMetricsDistributedStatementIDList,
                            COUNT(*) AS DistributedStatementIDCount
                        FROM dbo.QueryLog
                        WHERE
                            BatchID = {0}" -f $BatchID
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from query insights.") -CodeBlock $null
                    $DistributedStatementIDList = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                    if ($DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount -gt 0) {
                        $Count = $DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount
                        $List = $DistributedStatementIDList.Dataset.Tables.QueryInsightsDistributedStatementIDList

                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $Count) -CodeBlock $null

                        # Wait for the queries to show up in query insights or for 15 minutes. Whichever condition is hit first will break the loop.
                        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForQueryInsightsData)
                        $ContinueLoop = $true

                        # Look at query insights on the database where the batch ran to gather additional metrics.
                        do {
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
                                    CONCAT('UPDATE dbo.QueryLog SET QueryInsightsSessionID = ', QueryInsightsSessionID, ', QueryInsightsLoginName = ''', QueryInsightsLoginName, ''', QueryInsightsSubmitTime = ''', QueryInsightsSubmitTime, ''', QueryInsightsStartTime = ''', QueryInsightsStartTime, ''', QueryInsightsEndTime = ''', QueryInsightsEndTime, ''', QueryInsightsDurationInMS = ', QueryInsightsDurationInMS, ', QueryInsightsRowCount = ', QueryInsightsRowCount, ', QueryInsightsStatus = ''', QueryInsightsStatus, ''', QueryInsightsResultCacheHit = ', QueryInsightsResultCacheHit, ', QueryInsightsLabel = ''', QueryInsightsLabel, ''', QueryInsightsQueryText = ''', QueryInsightsQueryText,' '', LastUpdateTime = GETDATE() WHERE BatchID = {0} AND DistributedStatementID = ''', DistributedStatementID, ''';') AS UpdateQueryLogText
                                FROM QueryInsights
                                WHERE DistributedStatementID IN ({1})" -f $BatchID, $List
                            $QueryInsightsList = Invoke-FabricSQLCommand -Server $Server -Database $Database -Query $Query

                            Write-Host "***************************************"
                            Write-Host $Server
                            Write-Host $Database
                            Write-Host $List
                            Write-Host $Query
                            Write-Host "***************************************"
                            
                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in query insights is {0} and the current number is {1}." -f $Count, $QueryInsightsList.Dataset.Tables.Rows.Count) -CodeBlock $null
                            
                            if (($QueryInsightsList.Dataset.Tables.Rows.Count -ne $Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking query insights again.") -CodeBlock $null
                                start-sleep 60
                            }
                        
                            if ((Get-Date) -gt $WaitForJobsUntil) {
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in query insghts. Therefore, columns in the query log that contain query insights metrics may be incomplete." -f $WaitTimeInMinutesForQueryInsightsData) -CodeBlock $null
                                $ContinueLoop = $false
                            }
                        } while (
                            ($QueryInsightsList.Dataset.Tables.Rows.Count -ne $Count) -and ($true -eq $ContinueLoop)
                        )
                    }
                    else {
                        $Count = 0
                        $List = ""
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("No distributed statement ids were found in the query log.") -CodeBlock $null
                    }
                    
                    # Convert the query insights results to a string.
                    if ($QueryInsightsList.Dataset.Tables.Rows.Count -gt 0) {
                        $Query = $QueryInsightsList.Dataset.Tables.Rows.UpdateQueryLogText | Out-String
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has started.") -CodeBlock $null
                        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has ended.") -CodeBlock $null
                    }
                }
                #>


                <#
                # Update the query log with the details from capacity metrics. 
                if ($true -eq $CollectCapacityMetrics) {
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering CU usage from capacity metrics.") -CodeBlock $null
                    
                    # Run the command to get the list of distributed statement ids that need to have additional metrics collected from capacity metrics.
                    $Query = "
                        SELECT
                            '''' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), DistributedStatementID)), ''', ''') + '''' AS QueryInsightsDistributedStatementIDList,
                            '\""' + STRING_AGG(UPPER(CONVERT(NVARCHAR(MAX), DistributedStatementID)), '\"", \""') + '\""' AS CapacityMetricsDistributedStatementIDList,
                            COUNT(*) AS DistributedStatementIDCount
                        FROM dbo.QueryLog
                        WHERE
                            BatchID = {0}" -f $BatchID
                    Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from the query log.") -CodeBlock $null
                    $DistributedStatementIDList = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

                    if ($DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount -gt 0) {
                        $Count = $DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount
                        $List = $DistributedStatementIDList.Dataset.Tables.CapacityMetricsDistributedStatementIDList

                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $Count) -CodeBlock $null

                        # Wait for the queries to show up in capacity metrics or for 15 minutes. Whichever condition is hit first will break the loop.
                        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForCapacityMetricsData)
                        $ContinueLoop = $true

                        do {
                            # Get the data from Capacity Metrics. Use the batch start time to get the query dates.
                            [array]$FirstSlice     = Get-FabricCapacityMetrics -CapacityMetricsDatasetID $CapacityMetricsDatasetID -CapacityID $CapacityID -DistributedStatementIDList $List -QueryDate ([datetime]$BatchStartTime).ToString("yyyy-MM-dd 15:00:00")
                            [array]$SecondSlice    = Get-FabricCapacityMetrics -CapacityMetricsDatasetID $CapacityMetricsDatasetID -CapacityID $CapacityID -DistributedStatementIDList $List -QueryDate ([datetime]$BatchStartTime).AddDays(1).ToString("yyyy-MM-dd 03:00:00")
                            [array]$ThirdSlice     = Get-FabricCapacityMetrics -CapacityMetricsDatasetID $CapacityMetricsDatasetID -CapacityID $CapacityID -DistributedStatementIDList $List -QueryDate ([datetime]$BatchStartTime).AddDays(1).ToString("yyyy-MM-dd 15:00:00")

                            $CapacityMetrics = @()
                            ($FirstSlice + $SecondSlice + $ThirdSlice | Sort-Object OperationID | Get-Unique -AsString) | Group-Object WorkspaceName, ItemKind, ItemName, OperationId |
                            ForEach-Object {
                                $GroupByColumns = $_.name -split ', ';
                                $StartTime = ($_.group | Measure-Object -Property OperationStartTime -Minimum).Minimum;
                                $EndTime = ($_.group | Measure-Object -Property OperationEndTime -Maximum).Maximum;
                                $SumCUs = ($_.group | Measure-Object -Property Sum_CUs -Sum).Sum;
                                $SumDuration = ($_.group | Measure-Object -Property Sum_Duration -Sum).Sum;
                                $CapacityMetrics += [PScustomobject]@{WorkspaceName = $GroupByColumns[0]; ItemKind = $GroupByColumns[1]; ItemName = $GroupByColumns[2]; OperationID = $GroupByColumns[3]; StartTime = $StartTime; EndTime = $EndTime; SumCUs = $SumCUs; SumDuration = $SumDuration}
                            }

                            Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in capacity metrics is {0} and the current number is {1}." -f $Count, $CapacityMetrics.Count) -CodeBlock $null

                            if (($CapacityMetrics.Count -ne $Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking capacity metrics again.") -CodeBlock $null
                                start-sleep 60
                            }

                            if ((Get-Date) -gt $WaitForJobsUntil) {
                                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The batch completed more than {0} minutes ago and the queries have not appeared in capacity metrics. Therefore, columns in the query log that contain capacity metrics may be incomplete." -f $WaitTimeInMinutesForCapacityMetricsData) -CodeBlock $null
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
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("No distributed statement ids were found in the query log.") -CodeBlock $null
                    }
                    
                    # Convert the capacity metrics results to a string.
                    if ($CapacityMetrics.Count -gt 0) {
                        $Query = $null

                        foreach ($Item in $CapacityMetrics) {
                            # $Query += "EXEC dbo.Update_QueryLogCapacityMetrics @BatchID = {0}, @DistributedStatementID = '{1}', @CapacityMetricsStartTime = '{2}', @CapacityMetricsEndTime = '{3}', @CapacityMetricsCUs = {4}, @CapacityMetricsDurationInSeconds = {5};`r`n" -f $BatchID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration
                            $Query += "DECLARE @CapacityCUPricePerHour DECIMAL(18,6); SET @CapacityCUPricePerHour = (SELECT CapacityCUPricePerHour FROM dbo.Scenario WHERE ScenarioID = {6}); UPDATE dbo.QueryLog SET CapacityMetricsStartTime = {2}, CapacityMetricsEndTime = {3}, CapacityMetricsCUs = {4}, CapacityMetricsQueryPrice = CONVERT(DECIMAL(18,6), (@CapacityCUPricePerHour / 3600.) * {4}), CapacityMetricsDurationInSeconds = {5}, LastUpdateTime = GETDATE() WHERE BatchID = {0} AND DistributedStatementID = '{1}';`r`n" -f $BatchID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration, $ScenarioID
                        }

                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in capacity metrics has started.") -CodeBlock $null
                        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                        Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in capacity metrics has ended.") -CodeBlock $null
                    }
                }
                #>



                # End the current batch.
                $Query = "
                    UPDATE dbo.Batch
                    SET
                        Status			= 'Completed',
                        EndTime 		= GETDATE(),
                        LastUpdateTime 	= GETDATE()
                    WHERE
                        BatchID = {0}" -f $BatchID
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $BatchID -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Batch {0} has ended." -f $BatchID) -CodeBlock $null
                $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
                <#**********     Batch end     **********#>

                Write-Host ""


            <#####################################################################################################################################################################################
            # Check if there were errors during the batch.
            $Query = "EXEC dbo.Get_BatchErrorCount @BatchID = '{0}'" -f $BatchID
            $ErrorCount = (Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query).Dataset.Tables.Rows

            if($ErrorCount.ErrorCount -ne 0) {
                Write-Host "Batch needs to be rerun due to a failure."
            #>    
                <#
                Reminder: This section was to automatically rerun batches with an error. Consider adding this back in. 

                # Wait for 1 minute before running anything again. 
                # Start-Sleep -Seconds 60
                # $QueryText = "EXEC dbo.Create_BatchToRerunAfterFailure @BatchID = '{0}'" -f $BatchID
                # $NewBatchID = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -AccessToken $SQLAccessToken -query $QueryText

                # # Get the batch details.
                # Write-Host "Getting batch details."
                # $QueryText = "EXEC dbo.Get_Batch @BatchID = '{0}'" -f $NewBatchID.NewBatchID
                # $Batch = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -AccessToken $SQLAccessToken -query $QueryText

                # Run-Batch
                #>
            
            <#
            }
            ####################################################################################################################################################################################>
        }
    } else {
        Write-Host "No batches to process."
    }



# Update the query log with the details from query insights. 
if ($true -eq $CollectQueryInsights) {        
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
            s.ScenarioID = {0}" -f $ScenarioID
    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from query insights.") -CodeBlock $null
    $DistributedStatementIDList = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

    if ($DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount -gt 0) {
        $Count = $DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount
        $List = $DistributedStatementIDList.Dataset.Tables.QueryInsightsDistributedStatementIDList

        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $Count) -CodeBlock $null

        # Wait for the queries to show up in query insights or for 15 minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForQueryInsightsData)
        $ContinueLoop = $true

        # Look at query insights on the database where the batch ran to gather additional metrics.
        do {
            # Old - CONCAT('UPDATE dbo.QueryLog SET QueryInsightsSessionID = ', QueryInsightsSessionID, ', QueryInsightsLoginName = ''', QueryInsightsLoginName, ''', QueryInsightsSubmitTime = ''', QueryInsightsSubmitTime, ''', QueryInsightsStartTime = ''', QueryInsightsStartTime, ''', QueryInsightsEndTime = ''', QueryInsightsEndTime, ''', QueryInsightsDurationInMS = ', QueryInsightsDurationInMS, ', QueryInsightsRowCount = ', QueryInsightsRowCount, ', QueryInsightsStatus = ''', QueryInsightsStatus, ''', QueryInsightsResultCacheHit = ', QueryInsightsResultCacheHit, ', QueryInsightsLabel = ''', QueryInsightsLabel, ''', QueryInsightsQueryText = ''', QueryInsightsQueryText,' '', LastUpdateTime = GETDATE() FROM dbo.QueryLog AS ql LEFT JOIN dbo.Batch AS b ON ql.BatchID = b.BatchID LEFT JOIN dbo.Scenario AS s ON b.ScenarioID = s.ScenarioID WHERE s.ScenarioID = {0} AND DistributedStatementID = ''', DistributedStatementID, ''';') AS UpdateQueryLogText
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
                WHERE DistributedStatementID IN ({1})" -f $ScenarioID, $List
            $QueryInsightsList = Invoke-FabricSQLCommand -Server $Server -Database $Database -Query $Query
            
            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in query insights is {0} and the current number is {1}." -f $Count, $QueryInsightsList.Dataset.Tables.Rows.Count) -CodeBlock $null
            
            if (($QueryInsightsList.Dataset.Tables.Rows.Count -ne $Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking query insights again.") -CodeBlock $null
                start-sleep 60
            }
        
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
    
    # Convert the query insights results to a string.
    if ($QueryInsightsList.Dataset.Tables.Rows.Count -gt 0) {
        $Query = $QueryInsightsList.Dataset.Tables.Rows.UpdateQueryLogText | Out-String
        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has started.") -CodeBlock $null
        $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query
        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Updating the query log with the data available in query insights has ended.") -CodeBlock $null
    }
}






# Update the query log with the details from capacity metrics. 
if ($true -eq $CollectCapacityMetrics) {
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
            s.ScenarioID = {0}" -f $ScenarioID
    Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Gathering distributed statement ids from the query log.") -CodeBlock $null
    $DistributedStatementIDList = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query

    if ($DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount -gt 0) {
        $Count = $DistributedStatementIDList.Dataset.Tables.DistributedStatementIDCount
        $List = $DistributedStatementIDList.Dataset.Tables.CapacityMetricsDistributedStatementIDList

        Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("{0} distributed statement ids were found in the query log." -f $Count) -CodeBlock $null

        # Wait for the queries to show up in capacity metrics or for 15 minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForCapacityMetricsData)
        $ContinueLoop = $true

        do {
            # Get the data from Capacity Metrics. Use the batch start time to get the query dates.
            [array]$FirstSlice     = Get-FabricCapacityMetrics -CapacityMetricsDatasetID $CapacityMetricsDatasetID -CapacityID $CapacityID -DistributedStatementIDList $List -QueryDate ([datetime]$BatchStartTime).ToString("yyyy-MM-dd 15:00:00")
            [array]$SecondSlice    = Get-FabricCapacityMetrics -CapacityMetricsDatasetID $CapacityMetricsDatasetID -CapacityID $CapacityID -DistributedStatementIDList $List -QueryDate ([datetime]$BatchStartTime).AddDays(1).ToString("yyyy-MM-dd 03:00:00")
            [array]$ThirdSlice     = Get-FabricCapacityMetrics -CapacityMetricsDatasetID $CapacityMetricsDatasetID -CapacityID $CapacityID -DistributedStatementIDList $List -QueryDate ([datetime]$BatchStartTime).AddDays(1).ToString("yyyy-MM-dd 15:00:00")

            $CapacityMetrics = @()
            ($FirstSlice + $SecondSlice + $ThirdSlice | Sort-Object OperationID | Get-Unique -AsString) | Group-Object WorkspaceName, ItemKind, ItemName, OperationId |
            ForEach-Object {
                $GroupByColumns = $_.name -split ', ';
                $StartTime = ($_.group | Measure-Object -Property OperationStartTime -Minimum).Minimum;
                $EndTime = ($_.group | Measure-Object -Property OperationEndTime -Maximum).Maximum;
                $SumCUs = ($_.group | Measure-Object -Property Sum_CUs -Sum).Sum;
                $SumDuration = ($_.group | Measure-Object -Property Sum_Duration -Sum).Sum;
                $CapacityMetrics += [PScustomobject]@{WorkspaceName = $GroupByColumns[0]; ItemKind = $GroupByColumns[1]; ItemName = $GroupByColumns[2]; OperationID = $GroupByColumns[3]; StartTime = $StartTime; EndTime = $EndTime; SumCUs = $SumCUs; SumDuration = $SumDuration}
            }

            Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("The expected number of distributed statement ids in capacity metrics is {0} and the current number is {1}." -f $Count, $CapacityMetrics.Count) -CodeBlock $null

            if (($CapacityMetrics.Count -ne $Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Add-LogEntry -ScenarioID $ScenarioID -BatchID $null -ThreadID $null -IterationID $null -MessageType "Information" -MessageText ("Waiting 60 seconds before checking capacity metrics again.") -CodeBlock $null
                start-sleep 60
            }

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
    
    # Convert the capacity metrics results to a string.
    if ($CapacityMetrics.Count -gt 0) {
        $Query = $null

        foreach ($Item in $CapacityMetrics) {
            # $Query += "EXEC dbo.Update_QueryLogCapacityMetrics @BatchID = {0}, @DistributedStatementID = '{1}', @CapacityMetricsStartTime = '{2}', @CapacityMetricsEndTime = '{3}', @CapacityMetricsCUs = {4}, @CapacityMetricsDurationInSeconds = {5};`r`n" -f $BatchID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration
            # $Query += "DECLARE @CapacityCUPricePerHour DECIMAL(18,6); SET @CapacityCUPricePerHour = (SELECT CapacityCUPricePerHour FROM dbo.Scenario WHERE ScenarioID = {6}); UPDATE dbo.QueryLog SET CapacityMetricsStartTime = {2}, CapacityMetricsEndTime = {3}, CapacityMetricsCUs = {4}, CapacityMetricsQueryPrice = CONVERT(DECIMAL(18,6), (@CapacityCUPricePerHour / 3600.) * {4}), CapacityMetricsDurationInSeconds = {5}, LastUpdateTime = GETDATE() WHERE BatchID = {0} AND DistributedStatementID = '{1}';`r`n" -f $BatchID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration, $ScenarioID
            # $Query += "UPDATE dbo.QueryLog SET CapacityMetricsStartTime = '{2}', CapacityMetricsEndTime = '{3}', CapacityMetricsCUs = {4}, CapacityMetricsQueryPrice = CONVERT(DECIMAL(18,6), ((SELECT CONVERT(DECIMAL(18,6), CapacityCUPricePerHour) FROM dbo.Scenario WHERE ScenarioID = {6}) / 3600.) * {4}), CapacityMetricsDurationInSeconds = {5}, LastUpdateTime = GETDATE() WHERE BatchID = {0} AND DistributedStatementID = '{1}';`r`n" -f $BatchID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration, $ScenarioID
            # $Query += "UPDATE dbo.QueryLog SET CapacityMetricsStartTime = '{2}', CapacityMetricsEndTime = '{3}', CapacityMetricsCUs = {4}, CapacityMetricsQueryPrice = CONVERT(DECIMAL(18,6), ((SELECT CONVERT(DECIMAL(18,6), CapacityCUPricePerHour) FROM dbo.Scenario WHERE ScenarioID = {6}) / 3600.) * {4}), CapacityMetricsDurationInSeconds = {5}, LastUpdateTime = GETDATE() FROM dbo.QueryLog AS ql LEFT JOIN dbo.Batch AS b ON ql.BatchID = b.BatchID LEFT JOIN dbo.Scenario AS s ON b.ScenarioID = s.ScenarioID WHERE s.ScenarioID = {0} AND DistributedStatementID = '{1}';`r`n"  -f $ScenarioID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration, $ScenarioID
            $Query += "UPDATE dbo.QueryLog SET CapacityMetricsStartTime = '{2}', CapacityMetricsEndTime = '{3}', CapacityMetricsCUs = {4}, CapacityMetricsQueryPrice = CONVERT(DECIMAL(18,6), ((SELECT CONVERT(DECIMAL(18,6), CapacityCUPricePerHour) FROM dbo.Scenario WHERE ScenarioID = {6}) / 3600.) * {4}), CapacityMetricsDurationInSeconds = {5}, LastUpdateTime = GETDATE() WHERE ScenarioID = {0} AND DistributedStatementID = '{1}';`r`n"  -f $ScenarioID, $Item.OperationID, $Item.StartTime, $Item.EndTime, $Item.SumCUs, $Item.SumDuration, $ScenarioID
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
        Status = 'Completed',
        ScenarioLog = REPLACE('{1}', '\u0027', ''''),
        LastUpdateTime 	= GETDATE()
    WHERE ScenarioID = {0}" -f $ScenarioID, $LocalLog
    $null = Invoke-FabricSQLCommand -Server $FlightControlServer -Database $FlightControlDatabase -Query $Query


    }
}
else {
    Write-Host "No scenarios to process."
}

Write-Host ""




#1. Update the Get Batch logic where it checks to see if the prior run executed successfully. 






<#
    Notes for later: Consider code to pause the capacity if no other batches are using it to save cost. 
#>

<#
    1. Add a field to the batch table that specifies the compute engine. It could be Fabric DW, Lakehouse SQL Endpoint, etc. But if the compute is not Fabric DW or SQL Endpoint then we shoul not attempt capture the Fabric ids, capacity information etc. Perhaps that gets stored in a JSON field in the future so it can store whatever is needed for any compute engine in Fabric, Databricsk, Azure SQL, etc.
    2. PowerShell script will generate the TPCH and TPCDS tests and populate the batch, thread, iteration, and query tables. Queries will be generated in the proper order for the run type and the thread.
    3. Create a generic stored procedure for people to populate their own test scripts. Maybe make a powershell script that will read SQL files into the tables otherwise they can specify their own scripts in PowerShell to be populated.


    1. Separate script will populate the necessary tables.
    2. This script will collect a list of:
        1. batches (1 record for each batch - before batch starts it should check if the parent batch completed successfully assuming there is a parent batch)
        2. Threads (1 record for each thread in the batch)
        3. Thread + Iteration + Query (1 record for each thread + query + iteration combination)
    3. Get values from various API calls.
    4. Assign capacity and scale
    5. Start the threads
    6. Run the queries in the correct order for each Thread and for the correct number of iterations use measure-command to capture the runtime.
    7. Once all iterations have completed get query insights for the batch
    8. Get capacity metrics for the batch
    9. Update the batch log.
    No logs will be created for the thread or iteration. 
    Query log will always store the messages, it will optionally store the results. 
#>