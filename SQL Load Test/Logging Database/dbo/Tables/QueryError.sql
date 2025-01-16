DROP TABLE IF EXISTS [dbo].[QueryError]
GO

CREATE TABLE [dbo].[QueryError] (
    [QueryID]             VARCHAR(36)    NOT NULL,
	[Error]               NVARCHAR (MAX) NULL,
    [CreateTime]          DATETIME2 (6)  NULL,
    [LastUpdateTime]      DATETIME2 (6)  NULL
)
GO