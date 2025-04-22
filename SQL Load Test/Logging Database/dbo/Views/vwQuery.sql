DROP VIEW IF EXISTS dbo.vwQuery
GO

CREATE VIEW dbo.vwQuery
AS
WITH Batch AS (
	SELECT
		ScenarioID,
		ScenarioName,
		BatchID,
		BatchName,
		BatchDescription,
		LogDirectory,
		QueryDirectory,
		ThreadCount,
		IterationCount,
		WorkspaceID,
		WorkspaceName,
		ItemID,
		ItemName,
		ItemType,
		Server,
		DatabaseCompatibilityLevel,
		DatabaseCollation,
		CASE 
			WHEN CHARINDEX('_BIN_', DatabaseCollation) > 0 THEN 1
			WHEN CHARINDEX('_BIN2_', DatabaseCollation) > 0 THEN 1
			WHEN CHARINDEX('_CS_', DatabaseCollation) > 0 THEN 1
			WHEN CHARINDEX('_CI_', DatabaseCollation) > 0 THEN 0
			ELSE NULL END AS DatabaseIsCaseSensitive,
		DatabaseIsAutoCreateStatsOn,
		DatabaseIsAutoUpdateStatsOn,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		CapacityID,
		CapacityName,
		CapacitySubscriptionID,
		CapacityResourceGroupName,
		CapacitySize,
		CapacityUnitPricePerHour,
		CapacityRegion,
		Dataset,
		DataSize,
		DataStorage,
		StartTime AS BatchStartTime,
		EndTime AS BatchEndTime,
		DurationInMS AS BatchDurationInMS,
		CEILING(DurationInMS / 1000.) AS BatchDurationInS,
		Duration AS BatchDuration,
		HasError,
		HasWarning
	FROM dbo.Batch
),
Thread AS (
	SELECT
		BatchID,
		ThreadID,
		Thread,
		StartTime AS ThreadStartTime,
		EndTime AS ThreadEndTime,
		DurationInMS AS ThreadDurationInMS,
		CEILING(DurationInMS / 1000.) AS ThreadDurationInS,
		Duration AS ThreadDuration
	FROM dbo.Thread
),
Iteration AS (
	SELECT
		ThreadID,
		IterationID,
		Iteration,
		StartTime AS IterationStartTime,
		EndTime AS IterationEndTime,
		DurationInMS AS IterationDurationInMS,
		CEILING(DurationInMS / 1000.) AS IterationDurationInS,
		Duration AS IterationDuration
	FROM dbo.Iteration
),
Query AS (
	SELECT
		IterationID,
		QueryID,
		Sequence,
		QueryFilePath,
		QueryFileName,
		Status,
		StartTime AS QueryStartTime,
		EndTime AS QueryEndTime,
		DurationInMS AS QueryDurationInMS,
		CEILING(DurationInMS / 1000.) AS QueryDurationInS,
		Duration AS QueryDuration,
		DistributedStatementCount,
		RetryCount,
		RetryLimit,
		ResultsRecordCount,
		HasError,
		Command,
		QueryMessage
	FROM dbo.Query
),
Statement AS (
	SELECT
		QueryID,
		COUNT(StatementID) AS StatementCount,
		COUNT(QueryInsightsSessionID) AS StatementsWithQueryInsightsCount,
		COUNT(CapacityMetricsCapacityUnitSeconds) AS StatementsWithCapacityMetricsCount,
		STRING_AGG(NULLIF(CONVERT(NVARCHAR(MAX), DistributedStatementID), ''), ', ') AS DistributedStatementID,
		SUM(QueryInsightsDurationInMS) AS QueryInsightsDurationInMS,
		CEILING(SUM(QueryInsightsDurationInMS) / 1000.) AS QueryInsightsDurationInS,
		SUM(QueryInsightsAllocatedCPUTimeMS) AS QueryInsightsAllocatedCPUTimeMS,
		SUM(QueryInsightsDataScannedRemoteStorageMB) AS QueryInsightsDataScannedRemoteStorageMB,
		SUM(QueryInsightsDataScannedMemoryMB) AS QueryInsightsDataScannedMemoryMB,
		SUM(QueryInsightsDataScannedDiskMB) AS QueryInsightsDataScannedDiskMB,
		SUM(QueryInsightsRowCount) AS QueryInsightsRowCount,
		STRING_AGG(NULLIF(CONVERT(NVARCHAR(MAX), QueryInsightsStatus), ''), ', ') AS QueryInsightsStatus,
		STRING_AGG(NULLIF(CONVERT(NVARCHAR(MAX), QueryInsightsLabel), ''), ', ') AS QueryInsightsLabel,
		SUM(CapacityMetricsCapacityUnitSeconds) AS CapacityMetricsCapacityUnitSeconds,
		SUM(CapacityMetricsOperationCost) AS CapacityMetricsOperationCost,
		SUM(CapacityMetricsDurationInSeconds) AS CapacityMetricsDurationInSeconds,
		CONCAT('SELECT * FROM dbo.vwAllDetails WHERE QueryID = ''', QueryID, '''') AS StatementDetail
	FROM dbo.Statement
	GROUP BY
		QueryID
)

SELECT
	ROW_NUMBER() OVER(ORDER BY b.BatchStartTime, t.Thread, i.Iteration, q.Sequence) AS SortOrder,

	-- Batch
	b.ScenarioID,
	b.ScenarioName,
	b.BatchID,
	b.BatchName,
	b.BatchDescription,
	b.LogDirectory,
	b.QueryDirectory,
	b.ThreadCount,
	b.IterationCount,
	b.WorkspaceID,
	b.WorkspaceName,
	b.ItemID,
	b.ItemName,
	b.ItemType,
	b.Server,
	b.DatabaseCompatibilityLevel,
	b.DatabaseCollation,
	b.DatabaseIsCaseSensitive,
	b.DatabaseIsAutoCreateStatsOn,
	b.DatabaseIsAutoUpdateStatsOn,
	b.DatabaseIsVOrderEnabled,
	b.DatabaseIsResultSetCachingOn,
	b.CapacityID,
	b.CapacityName,
	b.CapacitySubscriptionID,
	b.CapacityResourceGroupName,
	b.CapacitySize,
	b.CapacityUnitPricePerHour,
	b.CapacityRegion,
	b.Dataset,
	b.DataSize,
	b.DataStorage,
	b.BatchStartTime,
	b.BatchEndTime,
	b.BatchDurationInMS,
	b.BatchDurationInS,
	b.BatchDuration,
	b.HasError AS BatchHasError,
	b.HasWarning AS BatchHasWarning,

	-- Thread
	t.ThreadID,
	t.Thread,
	t.ThreadStartTime,
	t.ThreadEndTime,
	t.ThreadDurationInMS,
	t.ThreadDurationInS,
	t.ThreadDuration,

	-- Iteration
	i.IterationID,
	i.Iteration,
	i.IterationStartTime,
	i.IterationEndTime,
	i.IterationDurationInMS,
	i.IterationDurationInS,
	i.IterationDuration,

	-- Query
	q.QueryID,
	q.Sequence,
	q.QueryFilePath,
	q.QueryFileName,
	q.Status,
	q.QueryStartTime,
	q.QueryEndTime,
	q.QueryDurationInMS,
	q.QueryDurationInS,
	q.QueryDuration,
	q.DistributedStatementCount,
	q.RetryCount,
	q.RetryLimit,
	q.ResultsRecordCount,
	q.HasError AS QueryHasError,
	q.Command,
	q.QueryMessage,

	-- Statement
	CONCAT('SELECT * FROM dbo.vwStatement WHERE BatchID = ''', b.BatchID, '''') AS StatementDetail,
	s.StatementCount,
	s.StatementsWithQueryInsightsCount,
	s.StatementsWithCapacityMetricsCount,
	s.DistributedStatementID,
	s.QueryInsightsDurationInMS,
	s.QueryInsightsDurationInS,
	s.QueryInsightsAllocatedCPUTimeMS,
	s.QueryInsightsDataScannedRemoteStorageMB,
	s.QueryInsightsDataScannedMemoryMB,
	s.QueryInsightsDataScannedDiskMB,
	s.QueryInsightsRowCount,
	s.QueryInsightsStatus,
	s.QueryInsightsLabel,
	s.CapacityMetricsCapacityUnitSeconds,
	s.CapacityMetricsOperationCost,
	s.CapacityMetricsDurationInSeconds
FROM Batch AS b
LEFT JOIN Thread AS t
	ON b.BatchID = t.BatchID
LEFT JOIN Iteration AS i
	ON t.ThreadID = i.ThreadID
LEFT JOIN Query AS q
	ON i.IterationID = q.IterationID
LEFT JOIN Statement AS s
	ON q.QueryID = s.QueryID
GO