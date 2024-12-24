DROP VIEW IF EXISTS reporting.TPC_PowerRun
GO

CREATE VIEW reporting.TPC_PowerRun
AS
WITH
BatchList AS (
	SELECT
		BatchID
	FROM dbo.Batch
	WHERE
		Dataset IN ('TPC-H', 'TPCH', 'TPC-DS', 'TPCDS')
		AND BatchName IN ('Power Run')
), Combined AS (
	SELECT
		BatchID,
		ThreadID,

		NULL AS HasError,
		NULL AS HasWarning,

		SUM(QueryDurationInMS) AS DurationInMS,
		SUM(CASE WHEN Iteration = 1 THEN QueryDurationInMS ELSE 0 END) AS Iteration1_DurationInMS,
		SUM(CASE WHEN Iteration = 2 THEN QueryDurationInMS ELSE 0 END) AS Iteration2_DurationInMS,
		SUM(CASE WHEN Iteration = 3 THEN QueryDurationInMS ELSE 0 END) AS Iteration3_DurationInMS,
		SUM(CASE WHEN Iteration = 4 THEN QueryDurationInMS ELSE 0 END) AS Iteration4_DurationInMS,

		SUM(QueryDurationInMS/1000.) AS DurationInS,
		SUM(CASE WHEN Iteration = 1 THEN QueryDurationInMS/1000. ELSE 0 END) AS Iteration1_DurationInS,
		SUM(CASE WHEN Iteration = 2 THEN QueryDurationInMS/1000. ELSE 0 END) AS Iteration2_DurationInS,
		SUM(CASE WHEN Iteration = 3 THEN QueryDurationInMS/1000. ELSE 0 END) AS Iteration3_DurationInS,
		SUM(CASE WHEN Iteration = 4 THEN QueryDurationInMS/1000. ELSE 0 END) AS Iteration4_DurationInS,

		SUM(TotalCapacityMetricsCapacityUnitSeconds) AS CapacityMetricsCUs,
		SUM(CASE WHEN Iteration = 1 THEN TotalCapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration1_CapacityMetricsCUs,
		SUM(CASE WHEN Iteration = 2 THEN TotalCapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration2_CapacityMetricsCUs,
		SUM(CASE WHEN Iteration = 3 THEN TotalCapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration3_CapacityMetricsCUs,
		SUM(CASE WHEN Iteration = 4 THEN TotalCapacityMetricsCapacityUnitSeconds ELSE 0 END) AS Iteration4_CapacityMetricsCUs,

		SUM(TotalCapacityMetricsOperationCost) AS CapacityMetricsQueryPrice,
		SUM(CASE WHEN Iteration = 1 THEN TotalCapacityMetricsOperationCost ELSE 0 END) AS Iteration1_CapacityMetricsQueryPrice,
		SUM(CASE WHEN Iteration = 2 THEN TotalCapacityMetricsOperationCost ELSE 0 END) AS Iteration2_CapacityMetricsQueryPrice,
		SUM(CASE WHEN Iteration = 3 THEN TotalCapacityMetricsOperationCost ELSE 0 END) AS Iteration3_CapacityMetricsQueryPrice,
		SUM(CASE WHEN Iteration = 4 THEN TotalCapacityMetricsOperationCost ELSE 0 END) AS Iteration4_CapacityMetricsQueryPrice
	FROM dbo.vwQuery
	GROUP BY
		BatchID,
		ThreadID
)

	SELECT
		BatchID,
		ThreadID,
		HasError,
		HasWarning,
		'Duration' AS Metric,
		FORMAT(DATEADD(ms, Iteration1_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration1,
		FORMAT(DATEADD(ms, Iteration2_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration2,
		FORMAT(DATEADD(ms, Iteration3_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration3,
		FORMAT(DATEADD(ms, Iteration4_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration4,
		FORMAT(DATEADD(ms, Iteration1_DurationInMS + Iteration2_DurationInMS + Iteration3_DurationInMS + Iteration4_DurationInMS, 0), 'HH:mm:ss.fff') AS Total,
		FORMAT(DATEADD(ms, (SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Minimum,
		FORMAT(DATEADD(ms, (SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Maximum,
		FORMAT(DATEADD(ms, (SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Average
	FROM Combined


	UNION ALL

	SELECT
		BatchID,
		ThreadID,
		HasError,
		HasWarning,
		'Duration in Milliseconds' AS Metric,
		FORMAT(Iteration1_DurationInMS, 'N0') AS Iteration1,
		FORMAT(Iteration2_DurationInMS, 'N0') AS Iteration2,
		FORMAT(Iteration3_DurationInMS, 'N0') AS Iteration3,
		FORMAT(Iteration4_DurationInMS, 'N0') AS Iteration4,
		FORMAT(Iteration1_DurationInMS + Iteration2_DurationInMS + Iteration3_DurationInMS + Iteration4_DurationInMS, 'N0') AS Total,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 'N0') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 'N0') AS Maximum,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 'N0') AS Average
	FROM Combined

	UNION ALL

	SELECT
		BatchID,
		ThreadID,
		HasError,
		HasWarning,
		'Duration in Seconds' AS Metric,
		FORMAT(Iteration1_DurationInS, 'N0') AS Iteration1,
		FORMAT(Iteration2_DurationInS, 'N0') AS Iteration2,
		FORMAT(Iteration3_DurationInS, 'N0') AS Iteration3,
		FORMAT(Iteration4_DurationInS, 'N0') AS Iteration4,
		FORMAT(Iteration1_DurationInS + Iteration2_DurationInS + Iteration3_DurationInS + Iteration4_DurationInS, 'N0') AS Total,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)), 'N0') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)), 'N0') AS Maximum,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)), 'N0') AS Average
	FROM Combined

	UNION ALL

	SELECT
		BatchID,
		ThreadID,
		HasError,
		HasWarning,
		'CUs' AS Metric,
		FORMAT(Iteration1_CapacityMetricsCUs, 'N4') AS Iteration1,
		FORMAT(Iteration2_CapacityMetricsCUs, 'N4') AS Iteration2,
		FORMAT(Iteration3_CapacityMetricsCUs, 'N4') AS Iteration3,
		FORMAT(Iteration4_CapacityMetricsCUs, 'N4') AS Iteration4,
		FORMAT(Iteration1_CapacityMetricsCUs + Iteration2_CapacityMetricsCUs + Iteration3_CapacityMetricsCUs + Iteration4_CapacityMetricsCUs, 'N4') AS Total,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col)), 'N4') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col)), 'N4') AS Maximum,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col)), 'N4') AS Average
	FROM Combined

	UNION ALL

	SELECT
		BatchID,
		ThreadID,
		HasError,
		HasWarning,
		'Query Price' AS Metric,
		FORMAT(Iteration1_CapacityMetricsQueryPrice, 'N6') AS Iteration1,
		FORMAT(Iteration2_CapacityMetricsQueryPrice, 'N6') AS Iteration2,
		FORMAT(Iteration3_CapacityMetricsQueryPrice, 'N6') AS Iteration3,
		FORMAT(Iteration4_CapacityMetricsQueryPrice, 'N6') AS Iteration4,
		FORMAT(Iteration1_CapacityMetricsQueryPrice + Iteration2_CapacityMetricsQueryPrice + Iteration3_CapacityMetricsQueryPrice + Iteration4_CapacityMetricsQueryPrice, 'N6') AS Total,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col)), 'N6') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col)), 'N6') AS Maximum,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col)), 'N6') AS Average
	FROM Combined
GO