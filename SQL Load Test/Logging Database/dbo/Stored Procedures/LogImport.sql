DROP PROCEDURE IF EXISTS dbo.ProcessLogImportData
GO

CREATE PROCEDURE dbo.ProcessLogImportData
AS
BEGIN
	/* Batch */
	INSERT INTO dbo.Batch
	SELECT
		JSON_VALUE(LogContent, '$.ScenarioID') AS ScenarioID,
		JSON_VALUE(LogContent, '$.ScenarioName') AS ScenarioName,
		JSON_VALUE(LogContent, '$.BatchID') AS BatchID,
		JSON_VALUE(LogContent, '$.BatchName') AS BatchName,
		JSON_VALUE(LogContent, '$.BatchDescription') AS BatchDescription,
		JSON_VALUE(LogContent, '$.QueryDirectory') AS QueryDirectory,
		JSON_VALUE(LogContent, '$.ThreadCount') AS ThreadCount,
		JSON_VALUE(LogContent, '$.IterationCount') AS IterationCount,
		JSON_VALUE(LogContent, '$.WorkspaceID') AS WorkspaceID,
		JSON_VALUE(LogContent, '$.WorkspaceName') AS WorkspaceName,
		JSON_VALUE(LogContent, '$.ItemID') AS ItemID,
		JSON_VALUE(LogContent, '$.ItemName') AS ItemName,
		JSON_VALUE(LogContent, '$.ItemType') AS ItemType,
		JSON_VALUE(LogContent, '$.Server') AS Server,
		JSON_VALUE(LogContent, '$.DatabaseCompatibilityLevel') AS DatabaseCompatibilityLevel,
		JSON_VALUE(LogContent, '$.DatabaseCollation') AS DatabaseCollation,
		JSON_VALUE(LogContent, '$.DatabaseIsAutoCreateStatsOn') AS DatabaseIsAutoCreateStatsOn,
		JSON_VALUE(LogContent, '$.DatabaseIsAutoUpdateStatsOn') AS DatabaseIsAutoUpdateStatsOn,
		JSON_VALUE(LogContent, '$.DatabaseIsVOrderEnabled') AS DatabaseIsVOrderEnabled,
		JSON_VALUE(LogContent, '$.DatabaseIsResultSetCachingOn') AS DatabaseIsResultSetCachingOn,
		JSON_VALUE(LogContent, '$.CapacityID') AS CapacityID,
		JSON_VALUE(LogContent, '$.CapacityName') AS CapacityName,
		JSON_VALUE(LogContent, '$.CapacitySubscriptionID') AS CapacitySubscriptionID,
		JSON_VALUE(LogContent, '$.CapacityResourceGroupName') AS CapacityResourceGroupName,
		JSON_VALUE(LogContent, '$.CapacitySize') AS CapacitySize,
		JSON_VALUE(LogContent, '$.CapacityUnitPricePerHour') AS CapacityUnitPricePerHour,
		JSON_VALUE(LogContent, '$.CapacityRegion') AS CapacityRegion,
		JSON_VALUE(LogContent, '$.Dataset') AS Dataset,
		JSON_VALUE(LogContent, '$.DataSize') AS DataSize,
		JSON_VALUE(LogContent, '$.DataStorage') AS DataStorage,
		JSON_VALUE(LogContent, '$.StartTime') AS StartTime,
		JSON_VALUE(LogContent, '$.EndTime') AS EndTime,
		JSON_VALUE(LogContent, '$.DurationInMS') AS DurationInMS,
		JSON_VALUE(LogContent, '$.Duration') AS Duration,
		GETDATE() AS CreateTime,
		GETDATE() AS LastUpdateTime
	FROM dbo.LogImport
	WHERE LogType = 'BatchLog'

	/* Thread */
	INSERT INTO dbo.Thread
	SELECT
		JSON_VALUE(LogContent, '$.ThreadID') AS ThreadID,
		JSON_VALUE(LogContent, '$.BatchID') AS BatchID,
		JSON_VALUE(LogContent, '$.Thread') AS Thread,
		JSON_VALUE(LogContent, '$.StartTime') AS StartTime,
		JSON_VALUE(LogContent, '$.EndTime') AS EndTime,
		JSON_VALUE(LogContent, '$.DurationInMS') AS DurationInMS,
		JSON_VALUE(LogContent, '$.Duration') AS Duration,
		GETDATE() AS CreateTime,
		GETDATE() AS LastUpdateTime
	FROM dbo.LogImport
	WHERE LogType = 'ThreadLog'

	/* Iteration */
	INSERT INTO dbo.Iteration
	SELECT
		JSON_VALUE(LogContent, '$.IterationID') AS IterationID,
		JSON_VALUE(LogContent, '$.BatchID') AS BatchID,
		JSON_VALUE(LogContent, '$.ThreadID') AS ThreadID,
		JSON_VALUE(LogContent, '$.Iteration') AS Iteration,
		JSON_VALUE(LogContent, '$.StartTime') AS StartTime,
		JSON_VALUE(LogContent, '$.EndTime') AS EndTime,
		JSON_VALUE(LogContent, '$.DurationInMS') AS DurationInMS,
		JSON_VALUE(LogContent, '$.Duration') AS Duration,
		GETDATE() AS CreateTime,
		GETDATE() AS LastUpdateTime
	FROM dbo.LogImport
	WHERE LogType = 'IterationLog'

	/* Query */
	INSERT INTO dbo.Query
	SELECT
		JSON_VALUE(LogContent, '$.QueryID') AS QueryID,
		JSON_VALUE(LogContent, '$.BatchID') AS BatchID,
		JSON_VALUE(LogContent, '$.ThreadID') AS ThreadID,
		JSON_VALUE(LogContent, '$.IterationID') AS IterationID,
		JSON_VALUE(LogContent, '$.Sequence') AS Sequence,
		JSON_VALUE(LogContent, '$.QueryFilePath') AS QueryFilePath,
		JSON_VALUE(LogContent, '$.QueryFileName') AS QueryFileName,
		JSON_VALUE(LogContent, '$.Status') AS Status,
		JSON_VALUE(LogContent, '$.StartTime') AS StartTime,
		JSON_VALUE(LogContent, '$.EndTime') AS EndTime,
		JSON_VALUE(LogContent, '$.DurationInMS') AS DurationInMS,
		JSON_VALUE(LogContent, '$.Duration') AS Duration,
		JSON_VALUE(LogContent, '$.DistributedStatementCount') AS DistributedStatementCount,
		JSON_VALUE(LogContent, '$.RetryCount') AS RetryCount,
		JSON_VALUE(LogContent, '$.RetryLimit') AS RetryLimit,
		JSON_VALUE(LogContent, '$.ResultsRecordCount') AS ResultsRecordCount,
		JSON_VALUE(LogContent, '$.HasError') AS HasError,
		JSON_VALUE(LogContent, '$.Command') AS Command,
		COALESCE(CONVERT(NVARCHAR(MAX), JSON_QUERY(LogContent,'$.QueryMessage')), JSON_VALUE(LogContent,'$.QueryMessage')) AS QueryMessage,
		GETDATE() AS CreateTime,
		GETDATE() AS LastUpdateTime
	FROM dbo.LogImport
	WHERE LogType = 'QueryLog'

	/* Statement */
	;WITH StatementLog AS (
		SELECT
			JSON_VALUE(LogContent, '$.StatementID') AS StatementID,
			JSON_VALUE(LogContent, '$.BatchID') AS BatchID,
			JSON_VALUE(LogContent, '$.ThreadID') AS ThreadID,
			JSON_VALUE(LogContent, '$.IterationID') AS IterationID,
			JSON_VALUE(LogContent, '$.QueryID') AS QueryID,
			JSON_VALUE(LogContent, '$.StatementMessage') AS StatementMessage,
			JSON_VALUE(LogContent, '$.DistributedStatementID') AS DistributedStatementID,
			JSON_VALUE(LogContent, '$.DistributedRequestID') AS DistributedRequestID,
			JSON_VALUE(LogContent, '$.QueryHash') AS QueryHash
		FROM dbo.LogImport
		WHERE LogType = 'StatementLog'
	),
	QueryInsights AS (
		SELECT
			JSON_VALUE(LogContent, '$.DistributedStatementID') AS StatementID,
			JSON_VALUE(LogContent, '$.SessionID') AS QueryInsightsSessionID,
			JSON_VALUE(LogContent, '$.LoginName') AS QueryInsightsLoginName,
			JSON_VALUE(LogContent, '$.SubmitTime') AS QueryInsightsSubmitTime,
			JSON_VALUE(LogContent, '$.StartTime') AS QueryInsightsStartTime,
			JSON_VALUE(LogContent, '$.EndTime') AS QueryInsightsEndTime,
			JSON_VALUE(LogContent, '$.DurationInMS') AS QueryInsightsDurationInMS,
			JSON_VALUE(LogContent, '$.AllocatedCPUTimeMS') AS QueryInsightsAllocatedCPUTimeMS,
			JSON_VALUE(LogContent, '$.DataScannedRemoteStorageMB') AS QueryInsightsDataScannedRemoteStorageMB,
			JSON_VALUE(LogContent, '$.DataScannedMemoryMB') AS QueryInsightsDataScannedMemoryMB,
			JSON_VALUE(LogContent, '$.DataScannedDiskMB') AS QueryInsightsDataScannedDiskMB,
			JSON_VALUE(LogContent, '$.RowCount') AS QueryInsightsRowCount,
			JSON_VALUE(LogContent, '$.Status') AS QueryInsightsStatus,
			JSON_VALUE(LogContent, '$.ResultCacheHit') AS QueryInsightsResultCacheHit,
			JSON_VALUE(LogContent, '$.Label') AS QueryInsightsLabel,
			JSON_VALUE(LogContent, '$.Command') AS QueryInsightsCommand
		FROM dbo.LogImport
		WHERE LogType = 'QueryInsights'
	),
	CapacityMetrics AS (
		SELECT
			JSON_VALUE(LogContent, '$.OperationID') AS StatementID,
			JSON_VALUE(LogContent, '$.StartTime') AS CapacityMetricsStartTime,
			JSON_VALUE(LogContent, '$.EndTime') AS CapacityMetricsEndTime,
			JSON_VALUE(LogContent, '$.CapacityUnitSeconds') AS CapacityMetricsCapacityUnitSeconds,
			JSON_VALUE(LogContent, '$.OperationCost') AS CapacityMetricsOperationCost,
			JSON_VALUE(LogContent, '$.DurationInSeconds') AS CapacityMetricsDurationInSeconds
		FROM dbo.LogImport
		WHERE LogType = 'CapacityMetrics'
	)

	INSERT INTO dbo.Statement
	SELECT
		SL.StatementID,
		SL.BatchID,
		SL.ThreadID,
		SL.IterationID,
		SL.QueryID,
		SL.StatementMessage,
		SL.DistributedStatementID,
		SL.DistributedRequestID,
		SL.QueryHash,
		QI.QueryInsightsSessionID,
		QI.QueryInsightsLoginName,
		QI.QueryInsightsSubmitTime,
		QI.QueryInsightsStartTime,
		QI.QueryInsightsEndTime,
		QI.QueryInsightsDurationInMS,
		QI.QueryInsightsAllocatedCPUTimeMS,
		QI.QueryInsightsDataScannedRemoteStorageMB,
		QI.QueryInsightsDataScannedMemoryMB,
		QI.QueryInsightsDataScannedDiskMB,
		QI.QueryInsightsRowCount,
		QI.QueryInsightsStatus,
		QI.QueryInsightsResultCacheHit,
		QI.QueryInsightsLabel,
		QI.QueryInsightsCommand,
		CM.CapacityMetricsStartTime,
		CM.CapacityMetricsEndTime,
		CM.CapacityMetricsCapacityUnitSeconds,
		CM.CapacityMetricsOperationCost,
		CONVERT(INT, ROUND(CM.CapacityMetricsDurationInSeconds, 0)) AS CapacityMetricsDurationInSeconds,
		GETDATE() AS CreateTime,
		GETDATE() AS LastUpdateTime
	FROM StatementLog AS SL
	LEFT JOIN QueryInsights AS QI
		ON SL.StatementID = QI.StatementID
	LEFT JOIN CapacityMetrics AS CM
		ON SL.StatementID = CM.StatementID

	/* Query Error */
	INSERT INTO dbo.QueryError
	SELECT
		JSON_VALUE(LogContent, '$.QueryID') AS QueryID,
		JSON_VALUE(LogContent, '$.Error') AS Error,
		GETDATE() AS CreateTime,
		GETDATE() AS LastUpdateTime
	FROM dbo.LogImport
	WHERE LogType = 'QueryError'
END
GO