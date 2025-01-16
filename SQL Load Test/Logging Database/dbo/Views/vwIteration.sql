DROP VIEW IF EXISTS dbo.vwIteration
GO

CREATE VIEW dbo.vwIteration
AS
WITH Batch AS (
	SELECT
		ScenarioID,
		ScenarioName,
		BatchID,
		BatchName,
		BatchDescription,
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
		Duration AS BatchDuration
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
		Duration AS IterationDuration
	FROM dbo.Iteration
),
Query AS (
	SELECT
		IterationID,
		COUNT(*) AS CountOfQueries,
		SUM(DurationInMS) AS TotalQueryDurationInMS,
		FORMAT(DATEADD(ms, SUM(DurationInMS), 0), 'HH:mm:ss.ffffff') AS TotalQueryDuration,
		SUM(DistributedStatementCount) AS TotalDistributedStatementCount,
		SUM(RetryCount) AS TotalRetryCount,
		SUM(ResultsRecordCount) AS TotalResultsRecordCount,
		CASE WHEN SUM(CONVERT(INT, HasError)) > 0 THEN 1 ELSE 0 END AS HasError
	FROM dbo.Query
	GROUP BY IterationID
),
Statement AS (
	SELECT
		IterationID,
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
		SUM(CapacityMetricsDurationInSeconds) AS TotalCapacityMetricsDurationInSeconds,
		CONCAT('SELECT * FROM dbo.vwAllDetails WHERE IterationID = ''', IterationID, '''') AS StatementDetail
	FROM dbo.Statement
	GROUP BY
		IterationID
)

SELECT
	ROW_NUMBER() OVER(ORDER BY b.BatchStartTime, t.Thread, i.Iteration) AS SortOrder,

	-- Batch
	b.ScenarioID,
	b.ScenarioName,
	b.BatchID,
	b.BatchName,
	b.BatchDescription,
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

	-- Thread
	t.ThreadID,
	t.Thread,
	t.ThreadStartTime,
	t.ThreadEndTime,
	t.ThreadDurationInMS,
	t.ThreadDuration,

	-- Iteration
	i.IterationID,
	i.Iteration,
	i.IterationStartTime,
	i.IterationEndTime,
	i.IterationDurationInMS,
	i.IterationDuration,

	-- Query
	q.CountOfQueries,
	q.TotalQueryDurationInMS,
	q.TotalQueryDuration,
	q.TotalDistributedStatementCount,
	q.TotalRetryCount,
	q.TotalResultsRecordCount,
	q.HasError,

	-- Statement
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
	s.TotalCapacityMetricsDurationInSeconds,
	s.StatementDetail
FROM Batch AS b
LEFT JOIN Thread AS t
	ON b.BatchID = t.BatchID
LEFT JOIN Iteration AS i
	ON t.ThreadID = i.ThreadID
LEFT JOIN Query AS q
	ON i.IterationID = q.IterationID
LEFT JOIN Statement AS s
	ON i.IterationID = s.IterationID
GO