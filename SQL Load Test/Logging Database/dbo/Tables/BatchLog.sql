DROP TABLE IF EXISTS [dbo].[BatchLog]
GO

CREATE TABLE [dbo].[BatchLog] (
	[BatchID]                      VARCHAR  (36)   NOT NULL,
    [LogContent]                   JSON            NULL,
    [CreateTime]                   DATETIME2 (6)   NULL,
	[LastUpdateTime]               DATETIME2 (6)   NULL
)
GO

CREATE CLUSTERED INDEX [ci_dbo_BatchLog_BatchID] ON [dbo].[BatchLog] ([BatchID])
GO