CREATE TABLE [dbo].[Thread] (
    [ThreadID]       INT            IDENTITY (1, 1) NOT NULL,
    [ScenarioID]     INT            NULL,
    [BatchID]        INT            NOT NULL,
    [Thread]         INT            NULL,
    [Status]         NVARCHAR (20)  NULL,
    [ThreadName]     NVARCHAR (200) NULL,
    [ThreadFolder]   NVARCHAR (500) NULL,
    [CountOfQueries] INT            NULL,
    [StartTime]      DATETIME2 (6)  NULL,
    [EndTime]        DATETIME2 (6)  NULL,
    [CreateTime]     DATETIME2 (6)  NULL,
    [LastUpdateTime] DATETIME2 (6)  NULL
);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Thread_ScenarioID]
    ON [dbo].[Thread]([ScenarioID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Thread_BatchID]
    ON [dbo].[Thread]([BatchID] ASC);
GO

CREATE CLUSTERED INDEX [ci_dbo_Thread_ThreadID]
    ON [dbo].[Thread]([ThreadID] ASC);
GO