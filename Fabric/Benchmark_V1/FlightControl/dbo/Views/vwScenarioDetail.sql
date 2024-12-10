DROP VIEW IF EXISTS dbo.vwScenarioDetail
GO

CREATE VIEW dbo.vwScenarioDetail
AS
SELECT
	-- Sceanrio details
	s.ScenarioID,
	s.ScenarioName,
	s.Status AS ScenarioStatus,
	s.WorkspaceID,
	s.WorkspaceName,
	s.ItemID,
	s.ItemName,
	s.ItemType,
	s.Server,
	s.CapacitySubscriptionID,
	s.CapacityResourceGroupName,
	s.CapacityName,
	s.CapacitySize,
	s.CapacityCUPricePerHour,
	s.CapacityRegion,
	s.CapacityID,
	s.Dataset,
	s.DataSize,
	s.DataStorage,
	s.StartTime AS ScenarioStartTime,
	s.EndTime AS ScenarioEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, s.StartTime, s.EndTime), 0), 'HH:mm:ss.fff') AS ScenarioDuration,
	s.HasError,
	s.HasWarning,
	CONCAT('SELECT * FROM dbo.vwScenarioLog WHERE ScenarioID = ', s.ScenarioID) AS ScenarioLog,
	
	-- Batch details
	b.BatchID,
	b.ParentBatchID,
	b.BatchDescription,
	b.BatchName,
	b.Status AS BatchStatus,
	b.BatchFolder,
	b.StartTime AS BatchStartTime,
	b.EndTime AS BatchEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, b.StartTime, b.EndTime), 0), 'HH:mm:ss.fff') AS BatchDuration,
	
	-- Thread details
	t.ThreadID,
	t.Thread,
	b.ThreadCount,
	t.ThreadName,
	t.Status AS ThreadStatus,
	t.ThreadFolder,
	t.CountOfQueries,
	t.StartTime AS ThreadStartTime,
	t.EndTime AS ThreadEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, t.StartTime, t.EndTime), 0), 'HH:mm:ss.fff') AS ThreadDuration,
	
	-- Iteration details
	i.IterationID,
	i.Iteration,
	b.IterationCount,
	i.Status AS IterationStatus,
	i.StartTime AS IterationStartTime,
	i.EndTime AS IterationEndTime,
	FORMAT(DATEADD(ms, DATEDIFF(MS, i.StartTime, i.EndTime), 0), 'HH:mm:ss.fff') AS IterationDuration,
	CONCAT('SELECT * FROM dbo.vwQuery WHERE IterationID = ', i.IterationID) AS QuerySummary,
	CONCAT('SELECT * FROM dbo.vwQueryDetail WHERE IterationID = ', i.IterationID) AS QueryDetail
FROM dbo.Scenario AS s
LEFT JOIN dbo.Batch AS b
	ON s.ScenarioID = b.ScenarioID
LEFT JOIN dbo.Thread AS t
	ON b.BatchID = t.ThreadID
LEFT JOIN dbo.Iteration AS i
	ON t.ThreadID = i.ThreadID
GO