
CREATE VIEW TPC_PowerRun
AS
WITH
ScenarioList AS (
	SELECT
		ScenarioID
	FROM dbo.Scenario
	WHERE
		Dataset IN ('TPC-H', 'TPCH', 'TPC-DS', 'TPCDS')
		AND ScenarioName IN ('Power Run')
		AND Status = 'Completed'
)

SELECT
	q.ScenarioID,
	q.BatchID,
	q.ThreadID,

	SUM(q.DurationInMS) AS DurationInMS,
	SUM(CASE WHEN Iteration = 1 THEN q.DurationInMS ELSE 0 END) AS Iteration1_DurationInMS,
	SUM(CASE WHEN Iteration = 2 THEN q.DurationInMS ELSE 0 END) AS Iteration2_DurationInMS,
	SUM(CASE WHEN Iteration = 3 THEN q.DurationInMS ELSE 0 END) AS Iteration3_DurationInMS,
	SUM(CASE WHEN Iteration = 4 THEN q.DurationInMS ELSE 0 END) AS Iteration4_DurationInMS,

	SUM(q.DurationInMS/1000.) AS DurationInS,
	SUM(CASE WHEN Iteration = 1 THEN q.DurationInMS/1000. ELSE 0 END) AS Iteration1_DurationInS,
	SUM(CASE WHEN Iteration = 2 THEN q.DurationInMS/1000. ELSE 0 END) AS Iteration2_DurationInS,
	SUM(CASE WHEN Iteration = 3 THEN q.DurationInMS/1000. ELSE 0 END) AS Iteration3_DurationInS,
	SUM(CASE WHEN Iteration = 4 THEN q.DurationInMS/1000. ELSE 0 END) AS Iteration4_DurationInS,

	SUM(q.CapacityMetricsCUs) AS CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 1 THEN q.CapacityMetricsCUs ELSE 0 END) AS Iteration1_CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 2 THEN q.CapacityMetricsCUs ELSE 0 END) AS Iteration2_CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 3 THEN q.CapacityMetricsCUs ELSE 0 END) AS Iteration3_CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 4 THEN q.CapacityMetricsCUs ELSE 0 END) AS Iteration4_CapacityMetricsCUs,

	SUM(q.CapacityMetricsQueryPrice) AS CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 1 THEN q.CapacityMetricsQueryPrice ELSE 0 END) AS Iteration1_CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 2 THEN q.CapacityMetricsQueryPrice ELSE 0 END) AS Iteration2_CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 3 THEN q.CapacityMetricsQueryPrice ELSE 0 END) AS Iteration3_CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 4 THEN q.CapacityMetricsQueryPrice ELSE 0 END) AS Iteration4_CapacityMetricsQueryPrice
FROM dbo.vwQuery AS q
INNER JOIN dbo.Iteration AS i
	ON q.IterationID = i.IterationID
GROUP BY
	q.ScenarioID,
	q.BatchID,
	q.ThreadID
GO

