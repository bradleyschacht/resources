DROP VIEW IF EXISTS dbo.vwBatchLog
GO

CREATE VIEW dbo.vwBatchLog
AS
WITH bl AS (
	SELECT
		BatchID,
		JSON_VALUE(LogContent, '$.MessageTime') AS MessageTime,
		JSON_VALUE(LogContent, '$.MessageType') AS MessageType,
		JSON_VALUE(LogContent, '$.Thread') AS Thread,
		JSON_VALUE(LogContent, '$.Iteration') AS Iteration,
		JSON_VALUE(LogContent, '$.Query') AS Query,
		JSON_VALUE(LogContent, '$.MessageText') AS MessageText
	FROM dbo.BatchLog
)

SELECT
	ROW_NUMBER() OVER(ORDER BY BatchID, MessageTime) AS SortOrder,
	BatchID,
	MessageTime,
	MessageType,
	Thread,
	Iteration,
	Query,
	MessageText
FROM bl