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
		AND ThreadCount = 1
		AND IterationCount = 4
), Combined AS (
	SELECT
		CONCAT('SELECT * FROM dbo.vwBatch WHERE BatchID = ''', BatchID, '''') AS BatchDetail,
		CASE
			WHEN BatchHasError = 1 THEN 'Red'
			WHEN BatchHasWarning = 1 OR SUM(StatementCount) != SUM(StatementsWithQueryInsightsCount) OR SUM(StatementCount) != SUM(StatementsWithCapacityMetricsCount) OR SUM(RetryCount) > 0 THEN 'Yellow'
			WHEN BatchHasError = 0 AND BatchHasWarning = 0 AND SUM(StatementCount) = SUM(StatementsWithQueryInsightsCount) AND SUM(StatementCount) = SUM(StatementsWithCapacityMetricsCount) AND SUM(RetryCount) = 0 THEN 'Green'
			ELSE 'Unknown'
			END AS BatchQuality,
		CASE
			WHEN BatchHasError = 1 THEN 'Red'
			WHEN SUM(CASE WHEN Status IN ('Unknown Status', 'Failure') THEN 1 ELSE 0 END) > 0 THEN 'Red'
			WHEN SUM(CASE WHEN Status NOT IN ('Success', 'Success after retry') THEN 1 ELSE 0 END) > 0 THEN 'Yellow'
			WHEN SUM(RetryCount) > 0 THEN 'Yellow'
			ELSE 'Green'
			END AS QueryExecutionQuality,
		CASE
			WHEN BatchHasError = 1 THEN 'Red'
			WHEN SUM(CASE WHEN Status IN ('Unknown Status', 'Failure') THEN 1 ELSE 0 END) > 0 THEN 'Red'
			WHEN SUM(StatementCount) != SUM(StatementsWithQueryInsightsCount) THEN 'Yellow'
			ELSE 'Green'
			END AS QueryInsightsQuality,
		CASE
			WHEN BatchHasError = 1 THEN 'Red'
			WHEN SUM(CASE WHEN Status IN ('Unknown Status', 'Failure') THEN 1 ELSE 0 END) > 0 THEN 'Red'
			WHEN SUM(StatementCount) != SUM(StatementsWithCapacityMetricsCount) THEN 'Yellow'
			ELSE 'Green'
			END AS CapacityMetricsQuality,
		CONCAT(
			'|' + CASE WHEN BatchHasError = 1 THEN 'Batch has errors' ELSE NULL END + '|',
			'|' + CASE WHEN BatchHasWarning = 1 THEN 'Batch has warnings' ELSE NULL END + '|',
			'|' + CASE WHEN SUM(RetryCount) > 0 THEN CONCAT('Query retry count: ', SUM(RetryCount)) ELSE NULL END + '|',
			'|' + CASE WHEN SUM(StatementCount) != SUM(StatementsWithQueryInsightsCount) OR SUM(StatementCount) IS NULL OR SUM(StatementsWithQueryInsightsCount) IS NULL THEN 'Query insights data may be incomplete' ELSE NULL END + '|',
			'|' + CASE WHEN SUM(StatementCount) != SUM(StatementsWithCapacityMetricsCount) OR SUM(StatementCount) IS NULL OR SUM(StatementsWithCapacityMetricsCount) IS NULL THEN 'Capacity metrics data may be incomplete' ELSE NULL END + '|',
			CASE WHEN BatchHasError = 0 AND BatchHasWarning = 0 AND SUM(StatementCount) = SUM(StatementsWithQueryInsightsCount) AND SUM(StatementCount) = SUM(StatementsWithCapacityMetricsCount) THEN '' ELSE NULL END
		) AS QualityDescription,
		BatchHasError,
		BatchHasWarning,
		SUM(RetryCount) AS QueryRetryCount,
		SUM(StatementCount) AS StatementCount,
		SUM(StatementsWithQueryInsightsCount) AS StatementsWithQueryInsightsCount,
		SUM(StatementsWithCapacityMetricsCount) AS StatementsWithCapacityMetricsCount,
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		ThreadID,

		SUM(QueryDurationInMS) AS DurationInMS,
		SUM(CASE WHEN Iteration = 1 THEN QueryDurationInMS ELSE 0 END) AS Iteration1_DurationInMS,
		SUM(CASE WHEN Iteration = 2 THEN QueryDurationInMS ELSE 0 END) AS Iteration2_DurationInMS,
		SUM(CASE WHEN Iteration = 3 THEN QueryDurationInMS ELSE 0 END) AS Iteration3_DurationInMS,
		SUM(CASE WHEN Iteration = 4 THEN QueryDurationInMS ELSE 0 END) AS Iteration4_DurationInMS,

		SUM(QueryDurationInMS/1000.) AS DurationInS,
		SUM(CASE WHEN Iteration = 1 THEN QueryDurationInS ELSE 0 END) AS Iteration1_DurationInS,
		SUM(CASE WHEN Iteration = 2 THEN QueryDurationInS ELSE 0 END) AS Iteration2_DurationInS,
		SUM(CASE WHEN Iteration = 3 THEN QueryDurationInS ELSE 0 END) AS Iteration3_DurationInS,
		SUM(CASE WHEN Iteration = 4 THEN QueryDurationInS ELSE 0 END) AS Iteration4_DurationInS,

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
	FROM dbo.vwQuery
	WHERE BatchID IN (SELECT BatchID FROM BatchList)
	GROUP BY
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsVOrderEnabled,
		ThreadID,
		BatchHasError,
		BatchHasWarning,
		DatabaseIsCaseSensitive,
		DatabaseIsResultSetCachingOn
)

	SELECT
		CONCAT(Dataset, ' | ', DataSize, ' | ', CapacitySize, ' | ', ItemType, ' | ', DataStorage, ' | ', DatabaseIsCaseSensitive, ' | ', DatabaseIsVOrderEnabled) AS PowerRunDescription,
		BatchDetail,
		BatchQuality,
		QueryExecutionQuality,
		QueryInsightsQuality,
		CapacityMetricsQuality,
		QualityDescription,
		BatchHasError,
		BatchHasWarning,
		QueryRetryCount,
		StatementCount,
		StatementsWithQueryInsightsCount,
		StatementsWithCapacityMetricsCount,
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		ThreadID,
		'Duration' AS Metric,
		FORMAT(DATEADD(ms, Iteration1_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration1,
		FORMAT(DATEADD(ms, Iteration2_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration2,
		FORMAT(DATEADD(ms, Iteration3_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration3,
		FORMAT(DATEADD(ms, Iteration4_DurationInMS, 0), 'HH:mm:ss.fff') AS Iteration4,
		FORMAT(DATEADD(ms, Iteration1_DurationInMS + Iteration2_DurationInMS + Iteration3_DurationInMS + Iteration4_DurationInMS, 0), 'HH:mm:ss.fff') AS Total,
		FORMAT(DATEADD(ms, (SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Average,
		FORMAT(DATEADD(ms, (SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Minimum,
		FORMAT(DATEADD(ms, (SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Maximum
	FROM Combined


	UNION ALL

	SELECT
		CONCAT(Dataset, ' | ', DataSize, ' | ', CapacitySize, ' | ', ItemType, ' | ', DataStorage, ' | ', DatabaseIsCaseSensitive, ' | ', DatabaseIsVOrderEnabled) AS PowerRunDescription,
		BatchDetail,
		BatchQuality,
		QueryExecutionQuality,
		QueryInsightsQuality,
		CapacityMetricsQuality,
		QualityDescription,
		BatchHasError,
		BatchHasWarning,
		QueryRetryCount,
		StatementCount,
		StatementsWithQueryInsightsCount,
		StatementsWithCapacityMetricsCount,
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		ThreadID,
		'Duration in Milliseconds' AS Metric,
		FORMAT(Iteration1_DurationInMS, 'N0') AS Iteration1,
		FORMAT(Iteration2_DurationInMS, 'N0') AS Iteration2,
		FORMAT(Iteration3_DurationInMS, 'N0') AS Iteration3,
		FORMAT(Iteration4_DurationInMS, 'N0') AS Iteration4,
		FORMAT(Iteration1_DurationInMS + Iteration2_DurationInMS + Iteration3_DurationInMS + Iteration4_DurationInMS, 'N0') AS Total,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 'N0') AS Average,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 'N0') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 'N0') AS Maximum
	FROM Combined

	UNION ALL

	SELECT
		CONCAT(Dataset, ' | ', DataSize, ' | ', CapacitySize, ' | ', ItemType, ' | ', DataStorage, ' | ', DatabaseIsCaseSensitive, ' | ', DatabaseIsVOrderEnabled) AS PowerRunDescription,
		BatchDetail,
		BatchQuality,
		QueryExecutionQuality,
		QueryInsightsQuality,
		CapacityMetricsQuality,
		QualityDescription,
		BatchHasError,
		BatchHasWarning,
		QueryRetryCount,
		StatementCount,
		StatementsWithQueryInsightsCount,
		StatementsWithCapacityMetricsCount,
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		ThreadID,
		'Duration in Seconds' AS Metric,
		FORMAT(Iteration1_DurationInS, 'N0') AS Iteration1,
		FORMAT(Iteration2_DurationInS, 'N0') AS Iteration2,
		FORMAT(Iteration3_DurationInS, 'N0') AS Iteration3,
		FORMAT(Iteration4_DurationInS, 'N0') AS Iteration4,
		FORMAT(Iteration1_DurationInS + Iteration2_DurationInS + Iteration3_DurationInS + Iteration4_DurationInS, 'N0') AS Total,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)), 'N0') AS Average,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)), 'N0') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInS), (Iteration3_DurationInS), (Iteration4_DurationInS)) AS X(Col)), 'N0') AS Maximum
	FROM Combined

	UNION ALL

	SELECT
		CONCAT(Dataset, ' | ', DataSize, ' | ', CapacitySize, ' | ', ItemType, ' | ', DataStorage, ' | ', DatabaseIsCaseSensitive, ' | ', DatabaseIsVOrderEnabled) AS PowerRunDescription,
		BatchDetail,
		BatchQuality,
		QueryExecutionQuality,
		QueryInsightsQuality,
		CapacityMetricsQuality,
		QualityDescription,
		BatchHasError,
		BatchHasWarning,
		QueryRetryCount,
		StatementCount,
		StatementsWithQueryInsightsCount,
		StatementsWithCapacityMetricsCount,
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		ThreadID,
		'CUs' AS Metric,
		FORMAT(Iteration1_CapacityMetricsCUs, 'N4') AS Iteration1,
		FORMAT(Iteration2_CapacityMetricsCUs, 'N4') AS Iteration2,
		FORMAT(Iteration3_CapacityMetricsCUs, 'N4') AS Iteration3,
		FORMAT(Iteration4_CapacityMetricsCUs, 'N4') AS Iteration4,
		FORMAT(Iteration1_CapacityMetricsCUs + Iteration2_CapacityMetricsCUs + Iteration3_CapacityMetricsCUs + Iteration4_CapacityMetricsCUs, 'N4') AS Total,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col)), 'N4') AS Average,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col)), 'N4') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_CapacityMetricsCUs), (Iteration3_CapacityMetricsCUs), (Iteration4_CapacityMetricsCUs)) AS X(Col)), 'N4') AS Maximum
	FROM Combined

	UNION ALL

	SELECT
		CONCAT(Dataset, ' | ', DataSize, ' | ', CapacitySize, ' | ', ItemType, ' | ', DataStorage, ' | ', DatabaseIsCaseSensitive, ' | ', DatabaseIsVOrderEnabled) AS PowerRunDescription,
		BatchDetail,
		BatchQuality,
		QueryExecutionQuality,
		QueryInsightsQuality,
		CapacityMetricsQuality,
		QualityDescription,
		BatchHasError,
		BatchHasWarning,
		QueryRetryCount,
		StatementCount,
		StatementsWithQueryInsightsCount,
		StatementsWithCapacityMetricsCount,
		ScenarioName,
		ScenarioID,
		BatchName,
		BatchDescription,
		BatchID,
		BatchStartTime,
		Dataset,
		DataSize,
		DataStorage,
		CapacitySize,
		WorkspaceName,
		ItemName,
		ItemType,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn,
		ThreadID,
		'Query Price' AS Metric,
		FORMAT(Iteration1_CapacityMetricsQueryPrice, 'N6') AS Iteration1,
		FORMAT(Iteration2_CapacityMetricsQueryPrice, 'N6') AS Iteration2,
		FORMAT(Iteration3_CapacityMetricsQueryPrice, 'N6') AS Iteration3,
		FORMAT(Iteration4_CapacityMetricsQueryPrice, 'N6') AS Iteration4,
		FORMAT(Iteration1_CapacityMetricsQueryPrice + Iteration2_CapacityMetricsQueryPrice + Iteration3_CapacityMetricsQueryPrice + Iteration4_CapacityMetricsQueryPrice, 'N6') AS Total,
		FORMAT((SELECT AVG(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col)), 'N6') AS Average,
		FORMAT((SELECT MIN(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col)), 'N6') AS Minimum,
		FORMAT((SELECT MAX(Col) FROM (VALUES (Iteration2_CapacityMetricsQueryPrice), (Iteration3_CapacityMetricsQueryPrice), (Iteration4_CapacityMetricsQueryPrice)) AS X(Col)), 'N6') AS Maximum
	FROM Combined
GO