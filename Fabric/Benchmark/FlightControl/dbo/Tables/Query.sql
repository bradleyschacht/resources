CREATE TABLE [dbo].[Query] (
    [QueryID]        INT            IDENTITY (1, 1) NOT NULL,
    [ScenarioID]     INT            NULL,
    [BatchID]        INT            NULL,
    [ThreadID]       INT            NULL,
    [IterationID]    INT            NULL,
    [QuerySequence]  INT            NULL,
    [QueryFile]      NVARCHAR (500) NULL,
    [QueryName]      NVARCHAR (500) NULL,
    [Query]          NVARCHAR (MAX) NULL,
    [Status]         NVARCHAR (20)  NULL,
    [StartTime]      DATETIME2 (6)  NULL,
    [EndTime]        DATETIME2 (6)  NULL,
    [QueryResults]   NVARCHAR (MAX) NULL,
    [QueryCustomLog] NVARCHAR (MAX) NULL,
    [QueryMessage]   NVARCHAR (MAX) NULL,
    [CreateTime]     DATETIME2 (6)  NULL,
    [LastUpdateTime] DATETIME2 (6)  NULL
);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Query_ScenarioID]
    ON [dbo].[Query]([ScenarioID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Query_BatchID]
    ON [dbo].[Query]([BatchID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Query_ThreadID]
    ON [dbo].[Query]([ThreadID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Query_IterationID]
    ON [dbo].[Query]([IterationID] ASC);
GO

CREATE CLUSTERED INDEX [ci_dbo_Query_QueryID]
    ON [dbo].[Query]([QueryID] ASC);
GO