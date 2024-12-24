DROP TABLE IF EXISTS [dbo].[Iteration]
GO

CREATE TABLE [dbo].[Iteration] (
    [IterationID]       NVARCHAR (36) NOT NULL,
    [BatchID]           NVARCHAR (36) NOT NULL,
    [ThreadID]          NVARCHAR (36) NOT NULL,
    [Iteration]         INT           NULL,
    [StartTime]         DATETIME2 (6) NULL,
    [EndTime]           DATETIME2 (6) NULL,
    [DurationInMS]      BIGINT        NULL,
    [Duration]          TIME (6)      NULL,
    [CreateTime]        DATETIME2 (6) NULL,
    [LastUpdateTime]    DATETIME2 (6) NULL
)
GO

/*
[Status]         NVARCHAR (20) NULL,
[CountOfQueries] INT            NULL,
Count of statements?
*/