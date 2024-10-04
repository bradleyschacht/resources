TRUNCATE TABLE automation.Scenario
TRUNCATE TABLE automation.Batch

DECLARE @CapacitySubscriptionID NVARCHAR(200) = '7e416de3-c506-4776-8270-83fd73c6cc37'
DECLARE @ResouceGroupName NVARCHAR(200) = 'scbradl-rg'
DECLARE @CapacityName NVARCHAR(200) = 'scbradlfabric10'

DECLARE @ScenarioList TABLE (
	ScenarioID					NVARCHAR(50),
	ScenarioSequence			DECIMAL(10,2),
	ScenarioName				NVARCHAR (200),
	WorkspaceName				NVARCHAR (200),
	ItemName					NVARCHAR (200),
	CapacitySubscriptionID		NVARCHAR (200),
	CapacityResourceGroupName	NVARCHAR (200),
	CapacityName				NVARCHAR (200),
	--CapacitySize				NVARCHAR (200),	
	Dataset						NVARCHAR (200),
	DataSize					NVARCHAR (200),
	DataStorage					NVARCHAR (200),
	IsActive					BIT
)

DECLARE @Scenario TABLE (
	ScenarioID					NVARCHAR(50),
	ScenarioSequence			DECIMAL(10,2),
	ScenarioName				NVARCHAR (200),
	WorkspaceName				NVARCHAR (200),
	ItemName					NVARCHAR (200),
	CapacitySubscriptionID		NVARCHAR (200),
	CapacityResourceGroupName	NVARCHAR (200),
	CapacityName				NVARCHAR (200),
	CapacitySize				NVARCHAR (200),	
	Dataset						NVARCHAR (200),
	DataSize					NVARCHAR (200),
	DataStorage					NVARCHAR (200),
	IsActive					BIT
)

DECLARE @Capacity TABLE (
	CapacitySizeSort 	INT,
	CapacitySize		VARCHAR(20),
	IsActive			BIT
)

DECLARE @Batch TABLE (
	ScenarioName		NVARCHAR(200),
	BatchSequence		INT,
	BatchDescription	NVARCHAR(200),
	IterationCount		INT,
	BatchFolder			NVARCHAR(200),
	IsActive			BIT
)

-- TPC-H GB_001
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCH_WH_GB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'GB_001', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCH_WH_GB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'GB_001', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCH_WH_GB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'GB_001', 'Import', 0)
-- TPC-H TB_001
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCH_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_001', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCH_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_001', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCH_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_001', 'Import', 0)
-- TPC-H TB_003
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCH_WH_TB_003', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_003', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCH_WH_TB_003', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_003', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCH_WH_TB_003', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_003', 'Import', 0)
-- TPC-H TB_010
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCH_WH_TB_010', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_010', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCH_WH_TB_010', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_010', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCH_WH_TB_010', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-H', 'TB_010', 'Import', 0)

-- TPC-DS GB_001
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCDS_WH_GB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'GB_001', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCDS_WH_GB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'GB_001', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCDS_WH_GB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'GB_001', 'Import', 0)
-- TPC-DS TB_001
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCDS_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_001', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCDS_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_001', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCDS_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_001', 'Import', 0)
-- TPC-DS TB_003
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCDS_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_001', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCDS_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_001', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCDS_WH_TB_001', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_001', 'Import', 0)
-- TPC-DS TB_010
INSERT INTO @ScenarioList VALUES (NEWID(), 1.0, 'Load', 					'Fabric Benchmarks 01', 'TPCDS_WH_TB_010', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_010', 'Import', 0)
INSERT INTO @ScenarioList VALUES (NEWID(), 2.0, 'Power Run', 				'Fabric Benchmarks 01', 'TPCDS_WH_TB_010', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_010', 'Import', 1)
INSERT INTO @ScenarioList VALUES (NEWID(), 3.0, 'Concurrency - 5 Users', 	'Fabric Benchmarks 01', 'TPCDS_WH_TB_010', @CapacitySubscriptionID, @ResouceGroupName, @CapacityName, 'TPC-DS', 'TB_010', 'Import', 0)

INSERT INTO @Batch VALUES ('Load', 						1, 'Load', 						1, 'C:\Benchmark\Scenarios\[Dataset]\[DataSize]\[BatchDescription]', 1)
INSERT INTO @Batch VALUES ('Power Run', 				1, 'Power Run', 				4, 'C:\Benchmark\Scenarios\[Dataset]\[DataSize]\[BatchDescription]', 1)
INSERT INTO @Batch VALUES ('Concurrency - 5 Users', 	1, 'Power Run', 				1, 'C:\Benchmark\Scenarios\[Dataset]\[DataSize]\[BatchDescription]', 1)
INSERT INTO @Batch VALUES ('Concurrency - 5 Users', 	2, 'Concurrency - 5 Users', 	1, 'C:\Benchmark\Scenarios\[Dataset]\[DataSize]\[BatchDescription]', 1)

INSERT INTO @Capacity VALUES (2, 		'F2', 		1)
INSERT INTO @Capacity VALUES (4, 		'F4', 		1)
INSERT INTO @Capacity VALUES (8, 		'F8', 		1)
INSERT INTO @Capacity VALUES (16, 		'F16', 		1)
INSERT INTO @Capacity VALUES (32, 		'F32', 		1)
INSERT INTO @Capacity VALUES (64, 		'F64', 		1)
INSERT INTO @Capacity VALUES (128, 		'F128', 	1)
INSERT INTO @Capacity VALUES (256, 		'F256', 	1)
INSERT INTO @Capacity VALUES (512, 		'F512', 	1)
INSERT INTO @Capacity VALUES (1024, 	'F1024', 	1)
INSERT INTO @Capacity VALUES (2048, 	'F2048', 	1)


INSERT INTO @Scenario
SELECT
	NEWID() AS ScenarioID,
	ROW_NUMBER() OVER(ORDER BY s.WorkspaceName, s.ItemName, s.Dataset, s.DataSize, c.CapacitySizeSort, s.ScenarioSequence) AS ScenarioSequence,
	s.ScenarioName,
	s.WorkspaceName,
	s.ItemName,
	s.CapacitySubscriptionID,
	s.CapacityResourceGroupName,
	s.CapacityName,
	c.CapacitySize,
	s.Dataset,
	s.DataSize,
	s.DataStorage,
	s.IsActive
FROM @ScenarioList AS s CROSS APPLY (SELECT CapacitySize, CapacitySizeSort FROM @Capacity WHERE IsActive = 1) AS c
WHERE
	   (CapacitySize = 'F64' AND DataSize = 'GB_001')
	OR (CapacitySize = 'F64' AND DataSize = 'TB_001')



INSERT INTO automation.Scenario
SELECT
	ScenarioID,
	ScenarioSequence,
	ScenarioName,
	WorkspaceName,
	ItemName,
	CapacitySubscriptionID,
	CapacityResourceGroupName,
	CapacityName,
	CapacitySize,
	Dataset,
	DataSize,
	DataStorage,
	IsActive
FROM @Scenario

INSERT INTO automation.Batch
SELECT
	s.ScenarioID,
	b.BatchSequence,
	b.BatchDescription,
	b.IterationCount,
	REPLACE(REPLACE(REPLACE(b.BatchFolder, '[Dataset]', s.DataSet),'[BatchDescription]', b.BatchDescription), '[DataSize]', s.DataSize) AS BatchFolder,
	b.IsActive
FROM @Batch AS b
INNER JOIN @Scenario AS s
ON b.ScenarioName = s.ScenarioName
ORDER BY s.ScenarioSequence, b.BatchSequence

SELECT * FROM automation.Scenario ORDER BY ScenarioSequence
SELECT * FROM automation.Batch ORDER BY BatchID