DROP VIEW IF EXISTS dbo.vwQueryDetail
GO

CREATE VIEW dbo.vwQueryDetail
AS
SELECT
	ROW_NUMBER() OVER(ORDER BY q.BatchID, q.ThreadID, q.IterationID, q.QuerySequence) AS SortOrder,
	-- Query detail
	q.BatchID,
	q.ThreadID,
	q.IterationID,
	q.QueryID,
	s.StatementID,
	q.QuerySequence,
	q.QueryFilePath,
	q.QueryFileName,
	q.Command,
	q.Status,
	q.StartTime,
	q.EndTime,
	
	-- Query Log detail
	s.DistributedStatementID,
	-- s.DistributedRequestID,
	s.QueryHash,
	s.QueryInsightsSessionID,
	s.QueryInsightsLoginName,
	s.QueryInsightsSubmitTime,
	s.QueryInsightsStartTime,
	s.QueryInsightsEndTime,
	s.QueryInsightsDurationInMS,
	s.QueryInsightsRowCount,
	s.QueryInsightsStatus,
	s.QueryInsightsResultCacheHit,
	s.QueryInsightsLabel,
	s.QueryInsightsCommand,
	s.CapacityMetricsStartTime,
	s.CapacityMetricsEndTime,
	s.CapacityMetricsCUs,
	s.CapacityMetricsQueryPrice,
	s.CapacityMetricsDurationInSeconds
FROM dbo.Query AS q
LEFT JOIN dbo.Statement AS s
	ON q.QueryID = s.QueryID
GO