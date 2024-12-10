CREATE TABLE [automation].[Batch] (
    [BatchID]          INT            IDENTITY (1, 1) NOT NULL,
    [ScenarioID]       NVARCHAR (50)  NULL,
    [BatchSequence]    INT            NULL,
    [BatchDescription] NVARCHAR (200) NULL,
    [IterationCount]   INT            NULL,
    [BatchFolder]      NVARCHAR (200) NULL,
    [IsActive]         BIT            NULL
);
GO

CREATE NONCLUSTERED INDEX [nci_automation_Batch_ScenarioID]
    ON [automation].[Batch]([ScenarioID] ASC);
GO

CREATE CLUSTERED INDEX [ci_automation_Batch_BatchID]
    ON [automation].[Batch]([BatchID] ASC);
GO