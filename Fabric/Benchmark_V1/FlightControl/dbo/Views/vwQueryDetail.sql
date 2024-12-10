DROP VIEW IF EXISTS dbo.vwQueryDetail
GO

CREATE VIEW dbo.vwQueryDetail
AS
SELECT
	ROW_NUMBER() OVER(ORDER BY q.ScenarioID, q.BatchID, q.ThreadID, q.IterationID, q.QuerySequence) AS SortOrder,
	-- Query detail
	q.ScenarioID,
	q.BatchID,
	q.ThreadID,
	q.IterationID,
	q.QueryID,
	ql.QueryLogID,
	q.QuerySequence,
	q.QueryFile,
	q.QueryName,
	q.Query,
	q.Status,
	q.StartTime,
	q.EndTime,
	CONCAT('SELECT QueryResults FROM dbo.Query WHERE QueryID = ', q.QueryID) AS QueryResults,
	CONCAT('SELECT QueryCustomLog FROM dbo.Query WHERE QueryID = ', q.QueryID) AS QueryCustomLog,
	CONCAT('SELECT QueryMessage FROM dbo.Query WHERE QueryID = ', q.QueryID) AS QueryMessage,
	
	-- Query Log detail
	ql.DistributedStatementID,
	-- ql.DistributedRequestID,
	ql.QueryHash,
	ql.QueryInsightsSessionID,
	ql.QueryInsightsLoginName,
	ql.QueryInsightsSubmitTime,
	ql.QueryInsightsStartTime,
	ql.QueryInsightsEndTime,
	ql.QueryInsightsDurationInMS,
	ql.QueryInsightsRowCount,
	ql.QueryInsightsStatus,
	ql.QueryInsightsResultCacheHit,
	ql.QueryInsightsLabel,
	ql.QueryInsightsQueryText,
	ql.CapacityMetricsStartTime,
	ql.CapacityMetricsEndTime,
	ql.CapacityMetricsCUs,
	ql.CapacityMetricsQueryPrice,
	ql.CapacityMetricsDurationInSeconds
FROM dbo.Query AS q
LEFT JOIN dbo.QueryLog AS ql
	ON q.QueryID = ql.QueryID
GO