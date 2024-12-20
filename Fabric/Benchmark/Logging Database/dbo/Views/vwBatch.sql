DROP VIEW IF EXISTS dbo.vwBatch
GO

CREATE VIEW dbo.vwBatch
AS
SELECT
	ScenarioID,
	ScenarioName,
	BatchID,
	BatchName,
	WorkspaceID,
	WorkspaceName,
	ItemID,
	ItemName,
	ItemType,
	Server,
	CapacitySubscriptionID,
	CapacityResourceGroupName,
	CapacityName,
	CapacitySize,
	CapacityCUPricePerHour,
	CapacityRegion,
	CapacityID,
	Dataset,
	DataSize,
	DataStorage,
	StartTime,
	EndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, StartTime, EndTime), 0), 'HH:mm:ss.fff') AS Duration,
	-- HasError,
	-- HasWarning,
	CONCAT('SELECT * FROM dbo.vwBatchDetail WHERE BatchID = ', BatchID) AS BatchLog,
	CreateTime,
	LastUpdateTime
FROM dbo.Batch
GO