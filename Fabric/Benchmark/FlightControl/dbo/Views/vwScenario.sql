DROP VIEW IF EXISTS dbo.vwScenario
GO

CREATE VIEW dbo.vwScenario
AS
SELECT
	ScenarioID,
	ScenarioName,
	Status,
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
	FORMAT(DATEADD(ms, DATEDIFF(MS, s.StartTime, s.EndTime), 0), 'HH:mm:ss.fff') AS Duration,
	HasError,
	HasWarning,
	CONCAT('SELECT * FROM dbo.vwScenarioLog WHERE ScenarioID = ', ScenarioID) AS ScenarioLog,
	CreateTime,
	LastUpdateTime
FROM dbo.Scenario AS s
GO