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
		Duration AS BatchDuration,
		HasError,
		HasWarning
	FROM dbo.Batch
),
Thread AS (
	SELECT
		BatchID,
		SUM(DurationInMS) AS TotalThreadDurationInMS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS TotalThreadDuration
	FROM dbo.Thread
	GROUP BY BatchID
),
Iteration AS (
	SELECT
		BatchID,
		SUM(DurationInMS) AS TotalIterationDurationInMS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS TotalIterationDuration
	FROM dbo.Iteration
	GROUP BY BatchID
),
Query AS (
	SELECT
		BatchID,
		COUNT(*) AS CountOfQueries,
		SUM(DurationInMS) AS TotalQueryDurationInMS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS TotalQueryDuration,
		SUM(DistributedStatementCount) AS TotalDistributedStatementCount,
		SUM(RetryCount) AS TotalRetryCount,
		SUM(ResultsRecordCount) AS TotalResultsRecordCount,
		CASE WHEN SUM(CONVERT(INT, HasError)) > 0 THEN 1 ELSE 0 END AS HasError
	FROM dbo.Query
	GROUP BY BatchID
),
Statement AS (
	SELECT
		BatchID,
		COUNT(StatementID) AS CountOfStatements,
		COUNT(QueryInsightsSessionID) AS CountOfStatementsWithQueryInsights,
		COUNT(CapacityMetricsCapacityUnitSeconds) AS CountOfStatementsWithCapacityMetrics,
		STRING_AGG(NULLIF(CONVERT(NVARCHAR(MAX), DistributedStatementID), ''), ', ') AS DistributedStatementID,
		SUM(QueryInsightsDurationInMS) AS TotalQueryInsightsDurationInMS,
		SUM(QueryInsightsAllocatedCPUTimeMS) AS TotalQueryInsightsAllocatedCPUTimeMS,
		SUM(QueryInsightsDataScannedRemoteStorageMB) AS TotalQueryInsightsDataScannedRemoteStorageMB,
		SUM(QueryInsightsDataScannedMemoryMB) AS TotalQueryInsightsDataScannedMemoryMB,
		SUM(QueryInsightsDataScannedDiskMB) AS TotalQueryInsightsDataScannedDiskMB,
		SUM(QueryInsightsRowCount) AS TotalQueryInsightsRowCount,
		STRING_AGG(NULLIF(CONVERT(NVARCHAR(MAX), QueryInsightsStatus), ''), ', ') AS QueryInsightsStatus,
		STRING_AGG(NULLIF(CONVERT(NVARCHAR(MAX), QueryInsightsLabel), ''), ', ') AS QueryInsightsLabel,
		SUM(CapacityMetricsCapacityUnitSeconds) AS TotalCapacityMetricsCapacityUnitSeconds,
		SUM(CapacityMetricsOperationCost) AS TotalCapacityMetricsOperationCost,
		SUM(CapacityMetricsDurationInSeconds) AS TotalCapacityMetricsDurationInSeconds
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
	b.BatchDuration,
	b.HasError AS BatchHasError,
	b.HasWarning AS BatchHasWarning,

	-- Thread
	CONCAT('SELECT * FROM dbo.vwThread WHERE BatchID = ''', b.BatchID, '''') AS ThreadDetail,
	t.TotalThreadDurationInMS,
	t.TotalThreadDuration,

	-- Iteration
	CONCAT('SELECT * FROM dbo.vwIteration WHERE BatchID = ''', b.BatchID, '''') AS IterationDetail,
	i.TotalIterationDurationInMS,
	i.TotalIterationDuration,

	-- Query
	CONCAT('SELECT * FROM dbo.vwQuery WHERE BatchID = ''', b.BatchID, '''') AS QueryDetail,
	q.CountOfQueries,
	q.TotalQueryDurationInMS,
	q.TotalQueryDuration,
	q.TotalDistributedStatementCount,
	q.TotalRetryCount,
	q.TotalResultsRecordCount,
	q.HasError AS QueryHasError,

	-- Statement
	CONCAT('SELECT * FROM dbo.vwStatement WHERE BatchID = ''', b.BatchID, '''') AS StatementDetail,
	s.CountOfStatements,
	s.CountOfStatementsWithQueryInsights,
	s.CountOfStatementsWithCapacityMetrics,
	s.DistributedStatementID,
	s.TotalQueryInsightsDurationInMS,
	s.TotalQueryInsightsAllocatedCPUTimeMS,
	s.TotalQueryInsightsDataScannedRemoteStorageMB,
	s.TotalQueryInsightsDataScannedMemoryMB,
	s.TotalQueryInsightsDataScannedDiskMB,
	s.TotalQueryInsightsRowCount,
	s.QueryInsightsStatus,
	s.QueryInsightsLabel,
	s.TotalCapacityMetricsCapacityUnitSeconds,
	s.TotalCapacityMetricsOperationCost,
	s.TotalCapacityMetricsDurationInSeconds
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