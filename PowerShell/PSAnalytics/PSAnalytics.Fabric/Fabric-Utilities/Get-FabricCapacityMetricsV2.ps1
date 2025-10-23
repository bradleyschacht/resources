function Get-FabricCapacityMetricsV2 {
	[CmdletBinding()]
    param (
		# Provide either a Capacity Metrics Workspace + Model Name or a Capacity Metrics Model ID.
		[Parameter(Mandatory = $false)] [string] $CapacityMetricsEventhouseUri,
		[Parameter(Mandatory = $false)] [string] $CapacityMetricsDatabase,
	
		# Provide either the name of the workspace where the activity occurred or the capacity.
        [Parameter(Mandatory = $false)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $Capacity,
		[Parameter(Mandatory = $false)] [double] $CUPricePerHour = 0.0,

        [Parameter(Mandatory = $true)] [array] $OperationIdList,
        [Parameter(Mandatory = $true)] [string] $Date,
        [Parameter(Mandatory = $false)] [string] $AccessToken
	)

	# If no capacity id is provided for the workspace where the queries were run, go look it up.
	if(!$Capacity) {
		$CapacityID = (Get-FabricWorkspace -Workspace $Workspace).capacityId
	}
	# Otherwise, validate or lookup the capacity id.
	else {
		$CapacityID = (Get-FabricCapacity -Capacity $Capacity).id
	}

	# Format the operation id list in the format of "ABC-DFE-GHI","123-456-789".
	$KqlOperationIdList = '"', ($OperationIdList -Join '", "'), '"' -join ""

	$Query = '
	let CapacityId      = "{0}";
	let RangeStart      = todatetime("{2}-{3}-{4} 00:00:00");
	let RangeEnd        = datetime_add("day", 2, RangeStart);
	let CUPricePerHour  = decimal({5});
	let OperationIdList = datatable (OperationID:dynamic) [dynamic([{1}])]
	| mv-expand OperationID
	| extend OperationID = toupper(OperationID);
	capacity_utilization
	| where todatetime(data.operationStartTime) >= RangeStart and todatetime(data.operationStartTime) <= RangeEnd
	| where data.capacityId == CapacityId
	| where toupper(data.operationId) in (OperationIdList)
	| summarize statusList = make_set(data.status), OperationCost = round(sum(toint(data.capacityUnitMs))/1000. * (CUPricePerHour / 3600.), 6), CapacityUnitSeconds = sum(toint(data.capacityUnitMs))/1000., DurationInSeconds = sum(toint(data.durationMs))/1000., StartTime = replace_string(format_datetime(min(todatetime(data.operationStartTime)), "yyyy-MM-dd HH:mm:ss"), " ", "T"), EndTime = replace_string(format_datetime(datetime_add("millisecond", sum(toint(data.durationMs)), min(todatetime(data.operationStartTime))), "yyyy-MM-dd HH:mm:ss"), " ", "T") by OperationID = toupper(tostring(data.operationId)), WorkspaceName = tostring(data.workspaceName), ItemName = tostring(data.itemName), ItemKind = tostring(data.itemKind)
	// | where statusList has_any ("Failure", "Success")
	| extend Status = case(statusList has ("Success"), "Success", statusList has ("Failure"), "Failure", "In Progress")
	| project-away statusList
	| project-reorder WorkspaceName, ItemKind, ItemName, OperationID, StartTime, EndTime, CapacityUnitSeconds, DurationInSeconds, OperationCost
	' -f $CapacityID, $KqlOperationIdList, ([datetime]$Date).Year, ([datetime]$Date).Month, ([datetime]$Date).Day, $CUPricePerHour
	
	$CapacityMetrics = Invoke-FabricKqlCommand -KustoQueryURI $CapacityMetricsEventhouseUri -Database $CapacityMetricsDatabase -Query $Query -AccessToken $AccessToken

	$CapacityMetrics
}