Clear-Host
function Invoke-SqlLoadTestGetQueryInsightsAndCapacityMetrics {
    param (
        [Parameter(Mandatory = $false)] [string] $LogDirectory,
        [Parameter(Mandatory = $false)] [switch] $QueryInsights,
        [Parameter(Mandatory = $false)] [switch] $OverwriteQueryInsights,
        [Parameter(Mandatory = $false)] [switch] $CapacityMetrics,
        [Parameter(Mandatory = $false)] [switch] $OverwriteCapacityMetrics,
        [Parameter(Mandatory = $false)] [string] $CapacityMetricsWorkspace,
        [Parameter(Mandatory = $false)] [string] $CapacityMetricsSemanticModelName          = "Fabric Capacity Metrics",
        [Parameter(Mandatory = $false)] [int32] $WaitTimeInMinutesForQueryInsightsData      = 0,
        [Parameter(Mandatory = $false)] [int32] $WaitTimeInMinutesForCapacityMetricsData    = 0
    )

    $ContinueScript = $true
    
    # Build the full directory paths for each of the files being used.
    $LogBatchPath           = Join-Path -Path $LogDirectory -ChildPath "01_Batch.txt"
    $LogStatementPath       = Join-Path -Path $LogDirectory -ChildPath "05_Statement.txt"
    $LogQueryInsightsPath   = Join-Path -Path $LogDirectory -ChildPath "06_QueryInsights.txt"
    $LogCapacityMetricsPath = Join-Path -Path $LogDirectory -ChildPath "07_CapacityMetrics.txt"

    # Check if the existing files have been populated.
    $QueryInsightsHasData   = if ((Get-Content -Path $LogQueryInsightsPath   | ConvertFrom-Json -AsHashtable).Count -gt 0) {$true} else {$false}
    $CapacityMetricsHasData = if ((Get-Content -Path $LogCapacityMetricsPath | ConvertFrom-Json -AsHashtable).Count -gt 0) {$true} else {$false}

    # Collect batch and statement information
    if ($true -eq $ContinueScript -and ($false -eq $QueryInsightsHasData -or $false -eq $CapacityMetricsHasData -or $true -eq $OverwriteCapacityMetrics -or $true -eq $OverwriteQueryInsights)) {
        $BatchLog = (Get-Content -Path $LogBatchPath     | ConvertFrom-Json -AsHashtable)
            $Server                   = $BatchLog.Server
            $ItemName                 = $BatchLog.ItemName
            $CapacityID               = $BatchLog.CapacityID
            $BatchStartTime           = $BatchLog.StartTime
            $CapacityUnitPricePerHour = $BatchLog.CapacityUnitPricePerHour
        $DistributedStatementIDList = (Get-Content -Path $LogStatementPath | ConvertFrom-Json -AsHashtable).Values.DistributedStatementID
    }
    else {
        Write-Host "Query Insights and Capacity Metrics files already contain data."
        $ContinueScript = $false
    }

    # Validate there is data in the statement log.
    if ($true -eq $ContinueScript -and ($DistributedStatementIDList.Count -eq 0)) {
        Write-Host "No statements found in the statement log." -ForegroundColor Red
        $ContinueScript = $false
    }

    # Validate the server and item names.
    if ($true -eq $ContinueScript -and ($true -eq $QueryInsights -and ($true -eq [string]::IsNullOrEmpty($Server) -or $true -eq [string]::IsNullOrEmpty($ItemName)))) {
        Write-Host "Missing parameters to gather query insights data." -ForegroundColor Red
        Write-Host ("Server: {0}" -f $Server)
        Write-Host ("Item Name: {0}" -f $ItemName)
        $ContinueScript = $false
    }

    # Validate Capacity Metrics Parameters
    if ($true -eq $ContinueScript -and ($true -eq $CapacityMetrics -and ($true -eq [string]::IsNullOrEmpty($CapacityID) -or $true -eq [string]::IsNullOrEmpty($BatchStartTime) -or $true -eq [string]::IsNullOrEmpty($CapacityUnitPricePerHour)))) {
        Write-Host "Missing parameters to gather capacity metrics data." -ForegroundColor Red
        Write-Host ("Batch Start Time: {0}" -f $BatchStartTime)
        Write-Host ("Capacity ID: {0}" -f $CapacityID)
        Write-Host ("Capacity Unit Price Per Hour: {0}" -f $CapacityUnitPricePerHour)
        $ContinueScript = $false
    }

    # Gather details from query insights.
    if ($true -eq $ContinueScript -and ($true -eq $QueryInsights -and ($false -eq $QueryInsightsHasData -or $true -eq $OverwriteQueryInsights))) {
        Write-Host "Gathering data from query insights."

        # Wait for the queries to show up in query insights or for X minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForQueryInsightsData)
        $ContinueLoop = $true

        # Look at query insights on the database where the batch ran to gather additional metrics.
        do {
            $QueryInsightsList = Get-FabricQueryInsights -Server $Server -ItemName $ItemName -OperationIdList $DistributedStatementIDList
            
            Write-Host ("The expected number of distributed statement ids in query insights is {0} and the current number is {1}." -f $DistributedStatementIDList.Count, $QueryInsightsList.Count)
            
            # If the statement count has not been met and the time limit has not expired, wait for a minute and then check again.
            if (($QueryInsightsList.Count -ne $DistributedStatementIDList.Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Write-Host ("Waiting 60 seconds before checking query insights again.")
                Start-Sleep 60
            }
        
            # If the time limit has expired, stop checking for new queries.
            if ((Get-Date) -gt $WaitForJobsUntil -and $QueryInsightsList.Count -ne $DistributedStatementIDList.Count) {
                Write-Host ("The batch completed more than {0} minutes ago and the queries have not appeared in query insights. Therefore, query insights data may be incomplete. {1} of {2} found." -f $WaitTimeInMinutesForQueryInsightsData, $QueryInsightsList.Count, $DistributedStatementIDList.Count) -ForegroundColor Red
                $ContinueLoop = $false
            }
        } while (
            ($QueryInsightsList.Count -ne $DistributedStatementIDList.Count) -and ($true -eq $ContinueLoop)
        )
        
        # Store the query insights results.
        if ($QueryInsightsList.Count -gt 0) {
            $QueryInsightsResults = $QueryInsightsList | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors
            Write-Host ("Writing query insights data to the file at {0}" -f $LogQueryInsightsPath)
            $QueryInsightsResults | ConvertTo-Json | Out-File $LogQueryInsightsPath -Force
        }
        else {
            Write-Host "No query insights data was found." -ForegroundColor Red
        }
    }

    # Gather details from capacity metrics. 
    if ($true -eq $ContinueScript -and ($true -eq $CapacityMetrics -and ($false -eq $CapacityMetricsHasData -or $true -eq $OverwriteCapacityMetrics))) {
        Write-Host ("Gathering data from capacity metrics.")

        # Wait for the queries to show up in capacity metrics or for X minutes. Whichever condition is hit first will break the loop.
        $WaitForJobsUntil = (Get-Date).AddMinutes($WaitTimeInMinutesForCapacityMetricsData)
        $ContinueLoop = $true

        # Look at capacity metrics gather the usage details.
        do {
            $CapacityMetricsResults = Get-FabricCapacityMetrics -CapacityMetricsWorkspace $CapacityMetricsWorkspace -CapacityMetricsSemanticModelName $CapacityMetricsSemanticModelName -Capacity $CapacityID -OperationIdList $DistributedStatementIDList -Date ([datetime]$BatchStartTime).ToString("yyyy-MM-dd 00:00:00") | Select-Object *, @{Name = "OperationCost"; Expression = {'{0:F6}' -f ([Math]::Round(($CapacityUnitPricePerHour / 60 / 60 * $_.CapacityUnitSeconds), 6))}}
            
            Write-Host ("The expected number of distributed statement ids in capacity metrics is {0} and the current number is {1}." -f $DistributedStatementIDList.Count, $CapacityMetricsResults.Count)

            # If the query count has not been met and the time limit has not expired, wait for a minute and then check again.
            if (($CapacityMetricsResults.Count -ne $DistributedStatementIDList.Count) -and ((Get-Date) -lt $WaitForJobsUntil)) {
                Write-Host ("Waiting 60 seconds before checking capacity metrics again.")
                Start-Sleep 60
            }

            # If the time limit has expired, stop checking for new queries.
            if ((Get-Date) -gt $WaitForJobsUntil -and $CapacityMetricsResults.Count -ne $DistributedStatementIDList.Count) {
                Write-Host ("The batch completed more than {0} minutes ago and the queries have not appeared in capacity metrics. Therefore, capacity metrics data may be incomplete. {1} of {2} found." -f $WaitTimeInMinutesForCapacityMetricsData, $CapacityMetricsResults.Count, $DistributedStatementIDList.Count) -ForegroundColor Red
                $ContinueLoop = $false
            }
        }
        while (
            ($CapacityMetricsResults.Count -ne $DistributedStatementIDList.Count) -and ($true -eq $ContinueLoop)
        )

        # Store the capacity metrics results.
        if ($CapacityMetricsResults.Count -gt 0) {
            Write-Host ("Writing capacity metrics data to the file at {0}" -f $LogCapacityMetricsPath)
            $CapacityMetricsResults | ConvertTo-Json | Out-File $LogCapacityMetricsPath -Force
        }
        else {
            Write-Host "No capacity metrics data was found." -ForegroundColor Red
        }
    }
}