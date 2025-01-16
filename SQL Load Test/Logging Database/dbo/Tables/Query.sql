DROP TABLE IF EXISTS [dbo].[Query]
GO

CREATE TABLE [dbo].[Query] (
    [QueryID]                       VARCHAR(36)    NOT NULL,
    [BatchID]                       VARCHAR(36)    NULL,
    [ThreadID]                      VARCHAR(36)    NULL,
    [IterationID]                   VARCHAR(36)    NULL,
    [Sequence]                      INT            NULL,
    [QueryFilePath]                 NVARCHAR (500) NULL,
    [QueryFileName]                 NVARCHAR (500) NULL,
    [Status]                        NVARCHAR (20)  NULL,
    [StartTime]                     DATETIME2 (6)  NULL,
    [EndTime]                       DATETIME2 (6)  NULL,
    [DurationInMS]                  BIGINT          NULL,
    [Duration]                      TIME (6)        NULL,
    [DistributedStatementCount]     INT            NULL,
	[RetryCount]                    INT            NULL,
	[RetryLimit]                    INT            NULL,
	[ResultsRecordCount]            INT            NULL,
	[HasError]                      BIT            NULL,
    [Command]                       NVARCHAR (MAX) NULL,
	[QueryMessage]                  NVARCHAR (MAX) NULL,
    [CreateTime]                    DATETIME2 (6)  NULL,
    [LastUpdateTime]                DATETIME2 (6)  NULL
)
GO

/*
[QueryResults]   NVARCHAR (MAX) NULL,
[QueryCustomLog] NVARCHAR (MAX) NULL,
*/