CREATE TABLE [dbo].[Iteration] (
    [IterationID]    INT           IDENTITY (1, 1) NOT NULL,
    [ScenarioID]     INT           NULL,
    [BatchID]        INT           NOT NULL,
    [ThreadID]       INT           NOT NULL,
    [Iteration]      INT           NULL,
    [Status]         NVARCHAR (20) NULL,
    [StartTime]      DATETIME2 (6) NULL,
    [EndTime]        DATETIME2 (6) NULL,
    [CreateTime]     DATETIME2 (6) NULL,
    [LastUpdateTime] DATETIME2 (6) NULL
);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Iteration_ScenarioID]
    ON [dbo].[Iteration]([ScenarioID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Iteration_BatchID]
    ON [dbo].[Iteration]([BatchID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_Iteration_ThreadID]
    ON [dbo].[Iteration]([ThreadID] ASC);
GO

CREATE CLUSTERED INDEX [ci_dbo_Iteration_IterationID]
    ON [dbo].[Iteration]([IterationID] ASC);
GO

