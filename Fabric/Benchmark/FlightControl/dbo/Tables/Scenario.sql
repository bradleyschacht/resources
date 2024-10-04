CREATE TABLE [dbo].[Scenario] (
    [ScenarioID]                INT             IDENTITY (1, 1) NOT NULL,
    [ScenarioName]              NVARCHAR (200)  NULL,
    [Status]                    NVARCHAR (20)   NULL,
    [WorkspaceID]               NVARCHAR (200)  NULL,
    [WorkspaceName]             NVARCHAR (200)  NULL,
    [ItemID]                    NVARCHAR (200)  NULL,
    [ItemName]                  NVARCHAR (200)  NULL,
    [ItemType]                  NVARCHAR (200)  NULL,
    [Server]                    NVARCHAR (200)  NULL,
    [CapacitySubscriptionID]    NVARCHAR (200)  NULL,
    [CapacityResourceGroupName] NVARCHAR (200)  NULL,
    [CapacityName]              NVARCHAR (200)  NULL,
    [CapacitySize]              NVARCHAR (200)  NULL,
    [CapacityCUPricePerHour]    DECIMAL (10, 2) NULL,
    [CapacityRegion]            NVARCHAR (200)  NULL,
    [CapacityID]                NVARCHAR (200)  NULL,
    [Dataset]                   NVARCHAR (200)  NULL,
    [DataSize]                  NVARCHAR (200)  NULL,
    [DataStorage]               NVARCHAR (200)  NULL,
    [StartTime]                 DATETIME2 (6)   NULL,
    [EndTime]                   DATETIME2 (6)   NULL,
    [ScenarioLog]               NVARCHAR (MAX)  NULL,
    [CreateTime]                DATETIME2 (6)   NULL,
    [LastUpdateTime]            DATETIME2 (6)   NULL
);
GO

CREATE CLUSTERED INDEX [ci_dbo_Scenario_ScenarioID]
    ON [dbo].[Scenario]([ScenarioID] ASC);
GO