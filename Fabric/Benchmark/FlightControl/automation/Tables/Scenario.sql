CREATE TABLE [automation].[Scenario] (
    [ScenarioID]                NVARCHAR (50)   NULL,
    [ScenarioSequence]          DECIMAL (10, 2) NULL,
    [ScenarioName]              NVARCHAR (200)  NULL,
    [WorkspaceName]             NVARCHAR (200)  NULL,
    [ItemName]                  NVARCHAR (200)  NULL,
    [CapacitySubscriptionID]    NVARCHAR (200)  NULL,
    [CapacityResourceGroupName] NVARCHAR (200)  NULL,
    [CapacityName]              NVARCHAR (200)  NULL,
    [CapacitySize]              NVARCHAR (200)  NULL,
    [Dataset]                   NVARCHAR (200)  NULL,
    [DataSize]                  NVARCHAR (200)  NULL,
    [DataStorage]               NVARCHAR (200)  NULL,
    [IsActive]                  BIT             NULL
);
GO

CREATE CLUSTERED INDEX [ci_automation_Scenario_ScenarioID]
    ON [automation].[Scenario]([ScenarioID] ASC);
GO