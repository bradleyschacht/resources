DROP VIEW IF EXISTS reporting.TPC_PowerRun_Flat
GO

CREATE VIEW reporting.TPC_PowerRun_Flat
AS
WITH PowerRunData AS (
SELECT
	b.BatchID,
	q.QueryFileName,
	q.QueryID,
	SUM(q.DurationInMS) AS DurationInMS,
	SUM(CASE WHEN Iteration = 1 THEN q.DurationInMS ELSE 0 END) AS Iteration1_DurationInMS,
	SUM(CASE WHEN Iteration = 2 THEN q.DurationInMS ELSE 0 END) AS Iteration2_DurationInMS,
	SUM(CASE WHEN Iteration = 3 THEN q.DurationInMS ELSE 0 END) AS Iteration3_DurationInMS,
	SUM(CASE WHEN Iteration = 4 THEN q.DurationInMS ELSE 0 END) AS Iteration4_DurationInMS,

	CONVERT(DECIMAL(18,4), SUM(q.DurationInMS/1000.)) AS DurationInS,
	CONVERT(DECIMAL(18,4), SUM(CASE WHEN Iteration = 1 THEN q.DurationInMS/1000. ELSE 0 END)) AS Iteration1_DurationInS,
	CONVERT(DECIMAL(18,4), SUM(CASE WHEN Iteration = 2 THEN q.DurationInMS/1000. ELSE 0 END)) AS Iteration2_DurationInS,
	CONVERT(DECIMAL(18,4), SUM(CASE WHEN Iteration = 3 THEN q.DurationInMS/1000. ELSE 0 END)) AS Iteration3_DurationInS,
	CONVERT(DECIMAL(18,4), SUM(CASE WHEN Iteration = 4 THEN q.DurationInMS/1000. ELSE 0 END)) AS Iteration4_DurationInS,

	SUM(CapacityMetricsCapacityUnitSeconds) AS CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 1 THEN CapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration1_CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 2 THEN CapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration2_CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 3 THEN CapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration3_CapacityMetricsCUs,
	SUM(CASE WHEN Iteration = 4 THEN CapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration4_CapacityMetricsCUs,

	SUM(CapacityMetricsOperationCost) AS CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 1 THEN CapacityMetricsOperationCost ELSE 0 END) AS Iteration1_CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 2 THEN CapacityMetricsOperationCost ELSE 0 END) AS Iteration2_CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 3 THEN CapacityMetricsOperationCost ELSE 0 END) AS Iteration3_CapacityMetricsQueryPrice,
	SUM(CASE WHEN Iteration = 4 THEN CapacityMetricsOperationCost ELSE 0 END) AS Iteration4_CapacityMetricsQueryPrice
FROM dbo.Batch AS b
INNER JOIN dbo.Iteration AS i
	ON b.BatchID = i.BatchID
INNER JOIN dbo.Query AS q
	ON i.BatchID = q.BatchID
	AND i.IterationID = q.IterationID
INNER JOIN dbo.Statement AS s
	ON q.BatchID = s.BatchID
	AND q.QueryID = s.QueryID
WHERE
	b.ThreadCount = 1
	AND b.IterationCount = 4
GROUP BY
	b.BatchID,
	q.QueryFileName,
	q.QueryID
)

SELECT
	BatchID,
	QueryFileName,
	QueryID,
	Iteration1_DurationInMS AS DurationInMS_Iteration1,
	Iteration2_DurationInMS AS DurationInMS_Iteration2,
	Iteration3_DurationInMS AS DurationInMS_Iteration3,
	Iteration4_DurationInMS AS DurationInMS_Iteration4,
	Iteration1_DurationInMS + Iteration2_DurationInMS + Iteration3_DurationInMS + Iteration4_DurationInMS AS DurationInMS_Total,
	(SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)) AS DurationInMS_Average,
	(SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)) AS DurationInMS_Minimum,
	(SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)) AS DurationInMS_Maximum,

	Iteration1_DurationInS AS DurationInS_Iteration1,
	Iteration2_DurationInS AS DurationInS_Iteration2,
	Iteration3_DurationInS AS DurationInS_Iteration3,
	Iteration4_DurationInS AS DurationInS_Iteration4,
	Iteration1_DurationInS + Iteration2_DurationInS + Iteration3_DurationInS + Iteration4_DurationInS AS DurationInS_Total,
	(SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)) AS DurationInS_Average,
	(SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)) AS DurationInS_Minimum,
	(SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)) AS DurationInS_Maximum,

	CONVERT(DECIMAL(20,4), Iteration1_CapacityMetricsCUs) AS CUs_Iteration1,
	CONVERT(DECIMAL(20,4), Iteration2_CapacityMetricsCUs) AS CUs_Iteration2,
	CONVERT(DECIMAL(20,4), Iteration3_CapacityMetricsCUs) AS CUs_Iteration3,
	CONVERT(DECIMAL(20,4), Iteration4_CapacityMetricsCUs) AS CUs_Iteration4,
	CONVERT(DECIMAL(20,4), Iteration1_CapacityMetricsCUs + Iteration2_CapacityMetricsCUs + Iteration3_CapacityMetricsCUs + Iteration4_CapacityMetricsCUs) AS CUs_Total,
	CONVERT(DECIMAL(20,4), (SELECT AVG(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col))) AS CUs_Average,
	CONVERT(DECIMAL(20,4), (SELECT MIN(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col))) AS CUs_Minimum,
	CONVERT(DECIMAL(20,4), (SELECT MAX(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col))) AS CUs_Maximum,

	CONVERT(DECIMAL(20,6), Iteration1_CapacityMetricsQueryPrice) AS QueryPrice_Iteration1,
	CONVERT(DECIMAL(20,6), Iteration2_CapacityMetricsQueryPrice) AS QueryPrice_Iteration2,
	CONVERT(DECIMAL(20,6), Iteration3_CapacityMetricsQueryPrice) AS QueryPrice_Iteration3,
	CONVERT(DECIMAL(20,6), Iteration4_CapacityMetricsQueryPrice) AS QueryPrice_Iteration4,
	CONVERT(DECIMAL(20,6), Iteration1_CapacityMetricsQueryPrice + Iteration2_CapacityMetricsQueryPrice + Iteration3_CapacityMetricsQueryPrice + Iteration4_CapacityMetricsQueryPrice) AS QueryPrice_Total,
	CONVERT(DECIMAL(20,6), (SELECT AVG(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col))) AS QueryPrice_Average,
	CONVERT(DECIMAL(20,6), (SELECT MIN(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col))) AS QueryPrice_Minimum,
	CONVERT(DECIMAL(20,6), (SELECT MAX(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col))) AS QueryPrice_Maximum
FROM PowerRunData
GO