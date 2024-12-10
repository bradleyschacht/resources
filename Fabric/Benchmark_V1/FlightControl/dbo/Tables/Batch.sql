DROP TABLE dbo.Batch
GO

CREATE TABLE [dbo].[Batch] (
    [BatchID]          INT            IDENTITY (1, 1) NOT NULL,
    [ParentBatchID]    INT            NULL,
    [ScenarioID]       INT            NULL,
    [BatchDescription] NVARCHAR (200) NULL,
    [BatchName]        NVARCHAR (200) NULL,
    [Status]           NVARCHAR (20)  NULL,
    [ThreadCount]      INT            NULL,
    [IterationCount]   INT            NULL,
    [BatchFolder]      NVARCHAR (500) NULL,
    [StartTime]        DATETIME2 (6)  NULL,
    [EndTime]          DATETIME2 (6)  NULL,
    [CreateTime]       DATETIME2 (6)  NULL,
    [LastUpdateTime]   DATETIME2 (6)  NULL
);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Batch_ScenarioID]
    ON [dbo].[Batch]([ScenarioID] ASC);
GO

CREATE CLUSTERED INDEX ci_dbo_Batch_BatchID ON dbo.Batch(BatchID ASC);
GO