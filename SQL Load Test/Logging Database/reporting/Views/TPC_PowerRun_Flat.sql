DROP VIEW IF EXISTS reporting.TPC_PowerRun_Flat
GO

CREATE VIEW reporting.TPC_PowerRun_Flat
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
		CONCAT(Dataset, ' | ', DataSize, ' | ', CapacitySize, ' | ', ItemType, ' | ', DataStorage, ' | ', DatabaseIsCaseSensitive, ' | ', DatabaseIsVOrderEnabled) AS PowerRunDescription,
		CONCAT('SELECT * FROM dbo.vwBatch WHERE BatchID = ''', BatchID, '''') AS BatchDetail,
		CASE
			WHEN BatchHasError = 1 THEN 'Red'
			WHEN BatchHasWarning = 1 OR SUM(StatementCount) != SUM(StatementsWithQueryInsightsCount) OR SUM(StatementCount) != SUM(StatementsWithCapacityMetricsCount) THEN 'Yellow'
			WHEN BatchHasError = 0 AND BatchHasWarning = 0 AND SUM(StatementCount) = SUM(StatementsWithQueryInsightsCount) AND SUM(StatementCount) = SUM(StatementsWithCapacityMetricsCount) THEN 'Green'
			ELSE 'Unknown'
			END AS BatchQuality,
		CONCAT(
			'|' + CASE WHEN BatchHasError = 1 THEN 'Batch has errors' ELSE NULL END + '|',
			'|' + CASE WHEN BatchHasWarning = 1 THEN 'Batch has warnings' ELSE NULL END + '|',
			'|' + CASE WHEN SUM(StatementCount) != SUM(StatementsWithQueryInsightsCount) THEN 'Query insights data may be incomplete' ELSE NULL END + '|',
			'|' + CASE WHEN SUM(StatementCount) != SUM(StatementsWithCapacityMetricsCount) THEN 'Capacity metrics data may be incomplete' ELSE NULL END + '|',
			CASE WHEN BatchHasError = 0 AND BatchHasWarning = 0 AND SUM(StatementCount) = SUM(StatementsWithQueryInsightsCount) AND SUM(StatementCount) = SUM(StatementsWithCapacityMetricsCount) THEN '' ELSE NULL END
		) AS BatchQualityDescription,

		BatchHasError,
		BatchHasWarning,
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
		DatabaseCollation,
		DatabaseIsVOrderEnabled,
		ThreadID,
		BatchHasError,
		BatchHasWarning,
		DatabaseIsCaseSensitive,
		DatabaseIsVOrderEnabled,
		DatabaseIsResultSetCachingOn
)

	SELECT
		PowerRunDescription,
		BatchDetail,
		BatchQuality,
		BatchQualityDescription,
		BatchHasError,
		BatchHasWarning,
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
		ThreadID,

		FORMAT(DATEADD(ms, Iteration1_DurationInMS, 0), 'HH:mm:ss.fff') AS Duration_Iteration1,
		FORMAT(DATEADD(ms, Iteration2_DurationInMS, 0), 'HH:mm:ss.fff') AS Duration_Iteration2,
		FORMAT(DATEADD(ms, Iteration3_DurationInMS, 0), 'HH:mm:ss.fff') AS Duration_Iteration3,
		FORMAT(DATEADD(ms, Iteration4_DurationInMS, 0), 'HH:mm:ss.fff') AS Duration_Iteration4,
		FORMAT(DATEADD(ms, Iteration1_DurationInMS + Iteration2_DurationInMS + Iteration3_DurationInMS + Iteration4_DurationInMS, 0), 'HH:mm:ss.fff') AS Duration_Total,
		FORMAT(DATEADD(ms, (SELECT AVG(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Duration_Average,
		FORMAT(DATEADD(ms, (SELECT MIN(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Duration_Minimum,
		FORMAT(DATEADD(ms, (SELECT MAX(Col) FROM (VALUES (Iteration2_DurationInMS), (Iteration3_DurationInMS), (Iteration4_DurationInMS)) AS X(Col)), 0), 'HH:mm:ss.fff') AS Duration_Maximum,

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
	FROM Combined
GO