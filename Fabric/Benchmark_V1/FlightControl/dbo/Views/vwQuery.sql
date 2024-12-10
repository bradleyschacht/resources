DROP VIEW IF EXISTS dbo.vwQuery
GO

CREATE VIEW dbo.vwQuery
AS
SELECT
	ROW_NUMBER() OVER(ORDER BY q.ScenarioID, q.BatchID, q.ThreadID, q.IterationID, q.QuerySequence) AS SortOrder,
	-- Query detail
	q.ScenarioID,
	q.BatchID,
	q.ThreadID,
	q.IterationID,
	q.QueryID,

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
	CONCAT('SELECT * FROM dbo.vwQueryDetail WHERE QueryID = ', q.QueryID) AS QueryDetail,
	COUNT(*) AS QueryLogEntries,
	COUNT(ql.QueryInsightsSessionID) AS QueryLogQueryInsightsFound,
	COUNT(ql.CapacityMetricsCUs) AS QueryLogCapacityMetricsFound,
	STRING_AGG(NULLIF(ql.DistributedStatementID, ''), ', ') AS DistributedStatementID,
	STRING_AGG(NULLIF(ql.QueryInsightsLabel, ''), ', ') AS QueryInsightsLabel,
	
	----- AS Duration
	SUM(CASE
		WHEN ql.QueryInsightsDurationInMS IS NOT NULL THEN ql.QueryInsightsDurationInMS
		ELSE ql.CapacityMetricsDurationInSeconds * 1000
		END) AS DurationInMS,
	SUM(ql.QueryInsightsRowCount) AS QueryInsightsRowCount,
	SUM(ql.CapacityMetricsCUs) AS CapacityMetricsCUs,
	SUM(ql.CapacityMetricsQueryPrice) AS CapacityMetricsQueryPrice
	
FROM dbo.Query AS q
LEFT JOIN dbo.QueryLog AS ql
	ON q.QueryID = ql.QueryID
GROUP BY
	q.ScenarioID,
	q.BatchID,
	q.ThreadID,
	q.IterationID,
	q.QueryID,
	q.QuerySequence,
	q.QueryFile,
	q.QueryName,
	q.Query,
	q.Status,
	q.StartTime,
	q.EndTime
GO