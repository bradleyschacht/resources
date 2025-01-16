DROP VIEW IF EXISTS dbo.vwStatement
GO

CREATE VIEW dbo.vwStatement
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
		QueryID,
		Sequence,
		QueryFilePath,
		QueryFileName,
		Status,
		StartTime AS QueryStartTime,
		EndTime AS QueryEndTime,
		DurationInMS AS QueryDurationInMS,
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
		StatementID,
		StatementMessage,
		DistributedStatementID,
		DistributedRequestID,
		QueryHash,
		QueryInsightsSessionID,
		QueryInsightsLoginName,
		QueryInsightsSubmitTime,
		QueryInsightsStartTime,
		QueryInsightsEndTime,
		QueryInsightsDurationInMS,
		QueryInsightsAllocatedCPUTimeMS,
		QueryInsightsDataScannedRemoteStorageMB,
		QueryInsightsDataScannedMemoryMB,
		QueryInsightsDataScannedDiskMB,
		QueryInsightsRowCount,
		QueryInsightsStatus,
		QueryInsightsResultCacheHit,
		QueryInsightsLabel,
		QueryInsightsCommand,
		CapacityMetricsStartTime,
		CapacityMetricsEndTime,
		CapacityMetricsCapacityUnitSeconds,
		CapacityMetricsOperationCost,
		CapacityMetricsDurationInSeconds
	FROM dbo.Statement
)

SELECT
	ROW_NUMBER() OVER(ORDER BY b.BatchStartTime, t.Thread, i.Iteration, q.Sequence, ISNULL(s.QueryInsightsStartTime, s.CapacityMetricsStartTime)) AS SortOrder,

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
	q.QueryID,
	q.Sequence,
	q.QueryFilePath,
	q.QueryFileName,
	q.Status,
	q.QueryStartTime,
	q.QueryEndTime,
	q.QueryDurationInMS,
	q.QueryDuration,
	q.DistributedStatementCount,
	q.RetryCount,
	q.RetryLimit,
	q.ResultsRecordCount,
	q.HasError,
	q.Command,
	q.QueryMessage,

	-- Statement
	s.StatementID,
	s.StatementMessage,
	s.DistributedStatementID,
	s.DistributedRequestID,
	s.QueryHash,
	s.QueryInsightsSessionID,
	s.QueryInsightsLoginName,
	s.QueryInsightsSubmitTime,
	s.QueryInsightsStartTime,
	s.QueryInsightsEndTime,
	s.QueryInsightsDurationInMS,
	s.QueryInsightsAllocatedCPUTimeMS,
	s.QueryInsightsDataScannedRemoteStorageMB,
	s.QueryInsightsDataScannedMemoryMB,
	s.QueryInsightsDataScannedDiskMB,
	s.QueryInsightsRowCount,
	s.QueryInsightsStatus,
	s.QueryInsightsResultCacheHit,
	s.QueryInsightsLabel,
	s.QueryInsightsCommand,
	s.CapacityMetricsStartTime,
	s.CapacityMetricsEndTime,
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