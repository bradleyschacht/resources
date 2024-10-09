DROP VIEW IF EXISTS dbo.vwScenarioLog
GO

CREATE VIEW dbo.vwScenarioLog
AS
SELECT
	ROW_NUMBER() OVER(ORDER BY sl.ScenarioID, sl.BatchID, sl.ThreadID, sl.IterationID, sl.MessageTime) AS ScenarioLogOrder,
	sl.ScenarioID,
	sl.BatchID,
	sl.ThreadID,
	sl.IterationID,
	sl.QueryID,
	CASE WHEN t.Thread IS NOT NULL THEN CONCAT('Thread ', t.Thread, ' of ', b.ThreadCount) ELSE NULL END AS Thread,
	CASE WHEN i.Iteration IS NOT NULL THEN CONCAT('Iteration ', i.Iteration, ' of ', b.IterationCount) ELSE NULL END AS Iteration,
	sl.MessageTime,
	sl.MessageType,
	sl.MessageText,
	sl.CodeBlock
FROM dbo.Scenario AS s
CROSS APPLY OPENJSON(NULLIF(s.ScenarioLog, ''))
	WITH (
		ScenarioID INT N'$.ScenarioID',
		BatchID INT N'$.BatchID',
		ThreadID INT N'$.ThreadID',
		IterationID INT N'$.IterationID',
		QueryID INT N'$.QueryID',
		MessageTime DATETIME2(6) N'$.MessageTime',
		MessageType NVARCHAR(200) N'$.MessageType',
		MessageText NVARCHAR(MAX) N'$.MessageText',
		CodeBlock INT N'$.CodeBlock'
	) AS sl
LEFT JOIN dbo.Batch AS b
	ON sl.BatchID = b.BatchID
LEFT JOIN dbo.Thread AS t
	ON sl.ThreadID = t.ThreadID
LEFT JOIN dbo.Iteration AS i
	ON sl.IterationID = i.IterationID
GO

