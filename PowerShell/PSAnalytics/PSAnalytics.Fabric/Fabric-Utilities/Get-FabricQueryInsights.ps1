function Get-FabricQueryInsights {
	[CmdletBinding()]
    param (
		# Provide the workspace server and item name.
        [Parameter(Mandatory = $false)] [string] $Server,
        [Parameter(Mandatory = $false)] [string] $ItemName,

        [Parameter(Mandatory = $true)] [array] $OperationIdList,
        [Parameter(Mandatory = $false)] [string] $AccessToken
	)

	if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

	# Format the operation id list including escaping the double quotes in the format of \""ABC-DFE-GHI\"",\""123-456-789\"".
	$SQLOperationIdList = ("'{0}'" -f ($OperationIdList -join "','")).ToUpper()

	$Query = "
		WITH QueryInsights AS (
			SELECT
				UPPER(distributed_statement_id) 	AS DistributedStatementID,
				session_id 							AS SessionID,
				login_name 							AS LoginName,
				CONVERT(NVARCHAR, submit_time, 21) 	AS SubmitTime,
				CONVERT(NVARCHAR, start_time, 21) 	AS StartTime,
				CONVERT(NVARCHAR, end_time, 21) 	AS EndTime,
				total_elapsed_time_ms 				AS DurationInMS,
				allocated_cpu_time_ms 				AS AllocatedCPUTimeMS,
				data_scanned_remote_storage_mb 		AS DataScannedRemoteStorageMB,
				data_scanned_memory_mb 				AS DataScannedMemoryMB,
				data_scanned_disk_mb 				AS DataScannedDiskMB,
				result_cache_hit 					AS ResultCacheHit,
				row_count 							AS [RowCount],
				[status] 							AS Status,
				NULLIF([label], '') 				AS Label,
				command 							AS Command
			FROM queryinsights.exec_requests_history	
		)
			
		SELECT
			*
		FROM QueryInsights
		WHERE DistributedStatementID IN ({0})
	" -f (("'{0}'" -f ($OperationIdList -join "','")).ToUpper())

	$QueryInsightsList = Invoke-FabricSQLCommand -Server $Server -Database $ItemName -Query $Query

	$QueryInsightsList.Dataset.Tables.Rows
}
