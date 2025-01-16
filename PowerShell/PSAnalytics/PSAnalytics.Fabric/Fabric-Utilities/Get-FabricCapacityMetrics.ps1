function Get-FabricCapacityMetrics {
	[CmdletBinding()]
    param (
		# Provide either a Capacity Metrics Workspace + Model Name or a Capacity Metrics Model ID.
		[Parameter(Mandatory = $false)] [string] $CapacityMetricsWorkspace,
		[Parameter(Mandatory = $false)] [string] $CapacityMetricsSemanticModelName = "Fabric Capacity Metrics",
		[Parameter(Mandatory = $false)] [string] $CapacityMetricsSemanticModelId,
	
		# Provide either the name of the workspace where the activity occurred or the capacity.
        [Parameter(Mandatory = $false)] [string] $Workspace,
        [Parameter(Mandatory = $false)] [string] $Capacity,

        [Parameter(Mandatory = $true)] [array] $OperationIdList,
        [Parameter(Mandatory = $true)] [string] $Date,
        [Parameter(Mandatory = $false)] [string] $AccessToken
	)

	if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

	# If no capacity metrics semantic model id is provided, go look it up.
	if(!$CapacityMetricsSemanticModelId) {
		$CapacityMetricsSemanticModelId = (Get-FabricItem -Workspace $CapacityMetricsWorkspace -Item $CapacityMetricsSemanticModelName -ItemType "SemanticModel").id
	}

	# If no capacity id is provided for the workspace where the queries were run, go look it up.
	if(!$Capacity) {
		$CapacityID = (Get-FabricWorkspace -Workspace $Workspace).capacityId
	}
	# Otherwise, validate or lookup the capacity id.
	else {
		$CapacityID = (Get-FabricCapacity -Capacity $Capacity).id
	}

	# Format the operation id list including escaping the double quotes in the format of \""ABC-DFE-GHI\"",\""123-456-789\"".
	$DaxOperationIdList = '\"', ($OperationIdList -Join '\", \"'), '\"' -join ""

	function Invoke-CapacityMetricsQuery {
		param(
			[datetime]$DaxDate
		)

		$DaxQuery = "
		DEFINE
				
		MPARAMETER 'CapacityID' 	= \""{0}\""
		MPARAMETER 'TimePoint' 		= (DATE({2}, {3}, {4}) + TIME({5}, {6}, {7}))

		VAR __Var_CapacityId	= {{\""{0}\""}}
		VAR __Var_OperationId	= {{{1}}}

		VAR __Filter_OperationId 	= TREATAS(__Var_OperationId, 'TimePointBackgroundDetail'[OperationId])
		VAR __Filter_CapacityId 	= TREATAS(__Var_CapacityId, 'Capacities'[capacityId])

		VAR __DS0Core = 
			SUMMARIZECOLUMNS(
				'Items'[WorkspaceName],
				'Items'[ItemKind],
				'Items'[ItemName],
				'TimePointBackgroundDetail'[OperationStartTime],
				'TimePointBackgroundDetail'[OperationEndTime],
				'TimePointBackgroundDetail'[OperationId],
				__Filter_OperationId,
				__Filter_CapacityId,
				\""Sum_CUs\"", CALCULATE(SUM('TimePointBackgroundDetail'[Total CU (s)])),
				\""Sum_Duration\"", CALCULATE(SUM('TimePointBackgroundDetail'[Duration (s)]))
			)
			
		EVALUATE
		__DS0Core" -f $CapacityID, $DaxOperationIdList, $DaxDate.Year, $DaxDate.Month, $DaxDate.Day, $DaxDate.Hour, $DaxDate.Minute, $DaxDate.Second

		$Uri = "https://api.powerbi.com/v1.0/myorg/datasets/{0}/executeQueries" -f $CapacityMetricsSemanticModelId
		$Headers = @{"Content-Type"="application/json"; Authorization=("Bearer {0}" -f ($AccessToken))}
		$Body = "{""queries"": [ {""query"": ""$DaxQuery""} ], ""serializerSettings"": {""includeNulls"": true}}"
		
		$Results = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120 -Body $Body

		$Results.results.tables.rows | Select-Object name, @{Name='WorkspaceName'; Expression={ $_.'Items[WorkspaceName]' }}, @{Name='ItemKind'; Expression={ $_.'Items[ItemKind]' }}, @{Name='ItemName'; Expression={ $_.'Items[ItemName]' }}, @{Name='OperationStartTime'; Expression={ $_.'TimePointBackgroundDetail[OperationStartTime]' }}, @{Name='OperationEndTime'; Expression={ $_.'TimePointBackgroundDetail[OperationEndTime]' }}, @{Name='OperationID'; Expression={ $_.'TimePointBackgroundDetail[OperationId]' }}, @{Name='CapacityUnitSeconds'; Expression={ $_.'[Sum_CUs]' }}, @{Name='DurationInSeconds'; Expression={ $_.'[Sum_Duration]' }}
	}

	# Check capacity metrics at 3 spots to ensure a record is found in capacity metrics throughout the smoothing period (24 horus).
	[array]$FirstSlice    = Invoke-CapacityMetricsQuery -DaxDate ([datetime]$Date).ToString("yyyy-MM-dd 15:00:00")
	[array]$SecondSlice   = Invoke-CapacityMetricsQuery -DaxDate ([datetime]$Date).AddDays(1).ToString("yyyy-MM-dd 03:00:00")
	[array]$ThirdSlice    = Invoke-CapacityMetricsQuery -DaxDate ([datetime]$Date).AddDays(1).ToString("yyyy-MM-dd 15:00:00")

	# Combine the three time slices and remove any duplicates as the same query can show up in multiple time slices over the smoothnig period (24 hours).
	$CapacityMetrics = @()
	($FirstSlice + $SecondSlice + $ThirdSlice | Sort-Object OperationID | Get-Unique -AsString) | Group-Object WorkspaceName, ItemKind, ItemName, OperationId |
	ForEach-Object {
		$GroupByColumns = $_.name -split ', ';
		$StartTime = ($_.group | Measure-Object -Property OperationStartTime -Minimum).Minimum;
		$EndTime = ($_.group | Measure-Object -Property OperationEndTime -Maximum).Maximum;
		$CapacityUnitSeconds = ($_.group | Measure-Object -Property CapacityUnitSeconds -Sum).Sum;
		$DurationInSeconds = ($_.group | Measure-Object -Property DurationInSeconds -Sum).Sum;
		$CapacityMetrics += [PScustomobject]@{WorkspaceName = $GroupByColumns[0]; ItemKind = $GroupByColumns[1]; ItemName = $GroupByColumns[2]; OperationID = $GroupByColumns[3]; StartTime = $StartTime; EndTime = $EndTime; CapacityUnitSeconds = $CapacityUnitSeconds; DurationInSeconds = $DurationInSeconds}
	}

	$CapacityMetrics
}
