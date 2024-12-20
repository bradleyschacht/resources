DROP VIEW IF EXISTS dbo.vwBatchDetail
GO

CREATE VIEW dbo.vwBatchDetail
AS
SELECT
	-- Batch details
	b.ScenarioID,
	b.ScenarioName,
	b.BatchID,
	b.BatchDescription,
	b.BatchName,
	b.QueryDirectory,
	b.WorkspaceID,
	b.WorkspaceName,
	b.ItemID,
	b.ItemName,
	b.ItemType,
	b.Server,
	b.CapacitySubscriptionID,
	b.CapacityResourceGroupName,
	b.CapacityName,
	b.CapacitySize,
	b.CapacityCUPricePerHour,
	b.CapacityRegion,
	b.CapacityID,
	b.Dataset,
	b.DataSize,
	b.DataStorage,
	b.StartTime AS BatchStartTime,
	b.EndTime AS BatchEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, b.StartTime, b.EndTime), 0), 'HH:mm:ss.fff') AS BatchDuration,
	-- s.HasError,
	-- s.HasWarning,
	-- CONCAT('SELECT * FROM dbo.vwBatchLog WHERE ScenarioID = ', s.ScenarioID) AS ScenarioLog, -- Replace with a PowerShell command to read the batch log file maybe?
	
	-- Thread details
	t.ThreadID,
	t.Thread,
	b.ThreadCount,
	t.StartTime AS ThreadStartTime,
	t.EndTime AS ThreadEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, t.StartTime, t.EndTime), 0), 'HH:mm:ss.fff') AS ThreadDuration,
	
	-- Iteration details
	i.IterationID,
	i.Iteration,
	b.IterationCount,
	i.StartTime AS IterationStartTime,
	i.EndTime AS IterationEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, i.StartTime, i.EndTime), 0), 'HH:mm:ss.fff') AS IterationDuration,
	CONCAT('SELECT * FROM dbo.vwQuery WHERE IterationID = ''', i.IterationID, '''') AS QuerySummary,
	CONCAT('SELECT * FROM dbo.vwQueryDetail WHERE IterationID = ''', i.IterationID, '''') AS QueryDetail
FROM dbo.Batch AS b
LEFT JOIN dbo.Thread AS t
	ON b.BatchID = t.BatchID
LEFT JOIN dbo.Iteration AS i
	ON t.ThreadID = i.ThreadID
GO