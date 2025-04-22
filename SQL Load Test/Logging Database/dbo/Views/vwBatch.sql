DROP VIEW IF EXISTS dbo.vwBatch
GO

CREATE VIEW dbo.vwBatch
AS
WITH
ScenarioStartTime AS (
	SELECT
		ScenarioID,
		MIN(StartTime) AS ScenarioStartTime
	FROM dbo.Batch
	GROUP BY ScenarioID
),
Batch AS (
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
		SUM(DurationInMS) AS ThreadDurationInMS,
		CEILING(SUM(DurationInMS) / 1000.) AS ThreadDurationInS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS ThreadDuration
	FROM dbo.Thread
	GROUP BY BatchID
),
Iteration AS (
	SELECT
		BatchID,
		SUM(DurationInMS) AS IterationDurationInMS,
		CEILING(SUM(DurationInMS) / 1000.) AS IterationDurationInS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS IterationDuration
	FROM dbo.Iteration
	GROUP BY BatchID
),
Query AS (
	SELECT
		BatchID,
		COUNT(*) AS QueryCount,
		SUM(DurationInMS) AS QueryDurationInMS,
		CEILING(SUM(DurationInMS) / 1000.) AS QueryDurationInS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS QueryDuration,
		SUM(DistributedStatementCount) AS DistributedStatementCount,
		SUM(RetryCount) AS RetryCount,
		SUM(ResultsRecordCount) AS ResultsRecordCount,
		CASE WHEN SUM(CONVERT(INT, HasError)) > 0 THEN 1 ELSE 0 END AS HasError
	FROM dbo.Query
	GROUP BY BatchID
),
Statement AS (
	SELECT
		BatchID,
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
		SUM(CapacityMetricsDurationInSeconds) AS CapacityMetricsDurationInSeconds
	FROM dbo.Statement
	GROUP BY
		BatchID
)

SELECT
	ROW_NUMBER() OVER(ORDER BY sst.ScenarioStartTime, b.BatchStartTime) AS SortOrder,

	-- Batch
	b.ScenarioID,
	b.ScenarioName,
	sst.ScenarioStartTime,
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
	CONCAT('SELECT * FROM dbo.vwBatchLog WHERE BatchID = ''', b.BatchID, '''') AS BatchLog,
	b.HasError AS BatchHasError,
	b.HasWarning AS BatchHasWarning,

	-- Thread
	CONCAT('SELECT * FROM dbo.vwThread WHERE BatchID = ''', b.BatchID, '''') AS ThreadDetail,
	t.ThreadDurationInMS,
	t.ThreadDurationInS,
	t.ThreadDuration,

	-- Iterationr
	CONCAT('SELECT * FROM dbo.vwIteration WHERE BatchID = ''', b.BatchID, '''') AS IterationDetail,
	i.IterationDurationInMS,
	i.IterationDurationInS,
	i.IterationDuration,

	-- Query
	CONCAT('SELECT * FROM dbo.vwQuery WHERE BatchID = ''', b.BatchID, '''') AS QueryDetail,
	q.QueryCount,
	q.QueryDurationInMS,
	q.QueryDurationInS,
	q.QueryDuration,
	q.DistributedStatementCount,
	q.RetryCount,
	q.ResultsRecordCount,
	q.HasError AS QueryHasError,

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
LEFT JOIN ScenarioStartTime AS sst
	ON b.ScenarioID = sst.ScenarioID
LEFT JOIN Thread AS t
	ON b.BatchID = t.BatchID
LEFT JOIN Iteration AS i
	ON t.BatchID = i.BatchID
LEFT JOIN Query AS q
	ON t.BatchID = q.BatchID
LEFT JOIN Statement AS s
	ON i.BatchID = s.BatchID
GO