DROP VIEW IF EXISTS dbo.vwQuery
GO

CREATE VIEW dbo.vwQuery
AS
SELECT
	ROW_NUMBER() OVER(ORDER BY q.BatchID, q.ThreadID, q.IterationID, q.QuerySequence) AS SortOrder,
	-- Query detail
	q.BatchID,
	q.ThreadID,
	q.IterationID,
	q.QueryID,

	q.QuerySequence,
	q.QueryFilePath,
	q.QueryFileName,
	q.Command,
	q.Status,
	q.StartTime,
	q.EndTime,
	CONCAT('SELECT * FROM dbo.QueryError WHERE QueryID = ''', q.QueryID, '''') AS QueryError,

	-- Statement detail
	CONCAT('SELECT * FROM dbo.Statement WHERE QueryID = ''', q.QueryID, '''') AS StatementDetail,
	COUNT(*) AS StatementsFound,
	COUNT(s.QueryInsightsSessionID) AS StatementQueryInsightsFound,
	COUNT(s.CapacityMetricsCUs) AS StatementCapacityMetricsFound,
	STRING_AGG(NULLIF(s.DistributedStatementID, ''), ', ') AS DistributedStatementID,
	STRING_AGG(NULLIF(s.QueryInsightsLabel, ''), ', ') AS QueryInsightsLabel,
	
	SUM(CASE
		WHEN s.QueryInsightsDurationInMS IS NOT NULL THEN s.QueryInsightsDurationInMS
		ELSE s.CapacityMetricsDurationInSeconds * 1000
		END) AS DurationInMS,
	SUM(s.QueryInsightsRowCount) AS QueryInsightsRowCount,
	SUM(s.CapacityMetricsCUs) AS CapacityMetricsCUs,
	SUM(s.CapacityMetricsQueryPrice) AS CapacityMetricsQueryPrice

FROM dbo.Query AS q
LEFT JOIN dbo.Statement AS s
	ON q.QueryID = s.QueryID
GROUP BY
	q.BatchID,
	q.ThreadID,
	q.IterationID,
	q.QueryID,
	q.QuerySequence,
	q.QueryFilePath,
	q.QueryFileName,
	q.Command,
	q.Status,
	q.StartTime,
	q.EndTime
GO
