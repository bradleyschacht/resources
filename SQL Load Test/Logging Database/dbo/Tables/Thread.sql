DROP TABLE IF EXISTS [dbo].[Thread]
GO

CREATE TABLE [dbo].[Thread] (
    [ThreadID]           NVARCHAR (36)  NOT NULL,
    [BatchID]            NVARCHAR (36)  NOT NULL,
    [Thread]             INT            NULL,
    [StartTime]          DATETIME2 (6)  NULL,
    [EndTime]            DATETIME2 (6)  NULL,
    [DurationInMS]       BIGINT          NULL,
    [Duration]           TIME (6)        NULL,
    [CreateTime]         DATETIME2 (6)  NULL,
    [LastUpdateTime]     DATETIME2 (6)  NULL
)
GO

/*
[CountOfQueries] INT            NULL,
Count of statements?
*/