DROP TABLE IF EXISTS [dbo].[Batch]
GO

CREATE TABLE [dbo].[Batch] (
    [ScenarioID]                   NVARCHAR (36)   NULL,
    [ScenarioName]                 NVARCHAR (200)  NULL,
	[BatchID]                      NVARCHAR (36)   NOT NULL,
	[BatchName]                    NVARCHAR (200)  NULL,
	[BatchDescription]             NVARCHAR (200)  NULL,
	[QueryDirectory]               NVARCHAR (500)  NULL,
    [ThreadCount]                  INT             NULL,
    [IterationCount]               INT             NULL,
	[WorkspaceID]                  NVARCHAR (200)  NULL,
    [WorkspaceName]                NVARCHAR (200)  NULL,
    [ItemID]                       NVARCHAR (200)  NULL,
    [ItemName]                     NVARCHAR (200)  NULL,
    [ItemType]                     NVARCHAR (200)  NULL,
    [Server]                       NVARCHAR (200)  NULL,
    [DatabaseCompatibilityLevel]   NVARCHAR (5)    NULL,
    [DatabaseCollation]            NVARCHAR (200)  NULL,
    [DatabaseIsAutoCreateStatsOn]  BIT             NULL,
    [DatabaseIsAutoUpdateStatsOn]  BIT             NULL,
    [DatabaseIsVOrderEnabled]      BIT             NULL,
    [DatabaseIsResultSetCachingOn] BIT             NULL,
    [CapacityID]                   NVARCHAR (200)  NULL,
	[CapacityName]                 NVARCHAR (200)  NULL,
	[CapacitySubscriptionID]       NVARCHAR (200)  NULL,
    [CapacityResourceGroupName]    NVARCHAR (200)  NULL,
    [CapacitySize]                 NVARCHAR (200)  NULL,
    [CapacityUnitPricePerHour]     DECIMAL (10, 2) NULL,
    [CapacityRegion]               NVARCHAR (200)  NULL,
    [Dataset]                      NVARCHAR (200)  NULL,
    [DataSize]                     NVARCHAR (200)  NULL,
    [DataStorage]                  NVARCHAR (200)  NULL,
    [StartTime]                    DATETIME2 (6)   NULL,
    [EndTime]                      DATETIME2 (6)   NULL,
    [DurationInMS]                 BIGINT          NULL,
    [Duration]                     TIME (6)        NULL,
    [CreateTime]                   DATETIME2 (6)   NULL,
	[LastUpdateTime]               DATETIME2 (6)   NULL
)
GO

/*    
[HasError]                  BIT             NULL,
[HasWarning]                BIT             NULL,
[ScenarioLog]               NVARCHAR (MAX)  NULL,
[Status]                    NVARCHAR (20)  NULL,
*/