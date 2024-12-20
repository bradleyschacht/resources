DROP TABLE IF EXISTS [dbo].[Batch]
GO
CREATE TABLE [dbo].[Batch] (
    [ScenarioID]                NVARCHAR (36)   NULL,
    [ScenarioName]              NVARCHAR (200)  NULL,
	[BatchID]                   NVARCHAR (36)   NOT NULL,
	[BatchName]                 NVARCHAR (200)  NULL,
	[BatchDescription]          NVARCHAR (200)  NULL,
	[QueryDirectory]            NVARCHAR (500)  NULL,
	--[Status]                    NVARCHAR (20)  NULL,
    [ThreadCount]               INT             NULL,
    [IterationCount]            INT             NULL,
	[WorkspaceID]               NVARCHAR (200)  NULL,
    [WorkspaceName]             NVARCHAR (200)  NULL,
    [ItemID]                    NVARCHAR (200)  NULL,
    [ItemName]                  NVARCHAR (200)  NULL,
    [ItemType]                  NVARCHAR (200)  NULL,
    [Server]                    NVARCHAR (200)  NULL,
    [CapacityID]                NVARCHAR (200)  NULL,
	[CapacityName]              NVARCHAR (200)  NULL,
	[CapacitySubscriptionID]    NVARCHAR (200)  NULL,
    [CapacityResourceGroupName] NVARCHAR (200)  NULL,
    [CapacitySize]              NVARCHAR (200)  NULL,
    [CapacityCUPricePerHour]    DECIMAL (10, 2) NULL,
    [CapacityRegion]            NVARCHAR (200)  NULL,
    [Dataset]                   NVARCHAR (200)  NULL,
    [DataSize]                  NVARCHAR (200)  NULL,
    [DataStorage]               NVARCHAR (200)  NULL,
    [StartTime]                 DATETIME2 (6)   NULL,
    [EndTime]                   DATETIME2 (6)   NULL,
    --[HasError]                  BIT             NULL,
    --[HasWarning]                BIT             NULL,
    --[ScenarioLog]               NVARCHAR (MAX)  NULL,
    [CreateTime]                DATETIME2 (6)   NULL,
	[LastUpdateTime]            DATETIME2 (6)   NULL
);
GO


DROP TABLE IF EXISTS [dbo].[Thread]
GO
CREATE TABLE [dbo].[Thread] (
    [ThreadID]       NVARCHAR (36)  NOT NULL,
    [BatchID]        NVARCHAR (36)  NOT NULL,
    [Thread]         INT            NULL,
    --[CountOfQueries] INT            NULL,
	--Count of statements?
    [StartTime]      DATETIME2 (6)  NULL,
    [EndTime]        DATETIME2 (6)  NULL,
    [CreateTime]     DATETIME2 (6)  NULL,
    [LastUpdateTime] DATETIME2 (6)  NULL
);
GO


DROP TABLE IF EXISTS [dbo].[Iteration]
GO
CREATE TABLE [dbo].[Iteration] (
    [IterationID]    NVARCHAR (36) NOT NULL,
    [BatchID]        NVARCHAR (36)  NOT NULL,
    [ThreadID]       NVARCHAR (36)  NOT NULL,
    [Iteration]      INT           NULL,
    -- [Status]         NVARCHAR (20) NULL,
	--[CountOfQueries] INT            NULL,
	--Count of statements?
    [StartTime]      DATETIME2 (6) NULL,
    [EndTime]        DATETIME2 (6) NULL,
    [CreateTime]     DATETIME2 (6) NULL,
    [LastUpdateTime] DATETIME2 (6) NULL
);
GO


DROP TABLE IF EXISTS [dbo].[Query]
GO
CREATE TABLE [dbo].[Query] (
    [QueryID]                   VARCHAR(36)    NOT NULL,
    [BatchID]                   VARCHAR(36)    NULL,
    [ThreadID]                  VARCHAR(36)    NULL,
    [IterationID]               VARCHAR(36)    NULL,
    [QuerySequence]             INT            NULL,
    [QueryFilePath]                 NVARCHAR (500) NULL,
    [QueryFileName]                 NVARCHAR (500) NULL,
    [Status]                    NVARCHAR (20)  NULL,
    [StartTime]                 DATETIME2 (6)  NULL,
    [EndTime]                   DATETIME2 (6)  NULL,
    [DistributedStatementCount] INT            NULL,
	[RetryCount]                INT            NULL,
	[RetryLimit]                INT            NULL,
	[ResultsRecordCount]        INT            NULL,
	[Errors]                    BIT            NULL,
    [Command]                   NVARCHAR (MAX) NULL,
	[QueryMessage]              NVARCHAR (MAX) NULL,
	-- [QueryResults]   NVARCHAR (MAX) NULL,
    -- [QueryCustomLog] NVARCHAR (MAX) NULL,
    [CreateTime]                DATETIME2 (6)  NULL,
    [LastUpdateTime]            DATETIME2 (6)  NULL
);


DROP TABLE IF EXISTS [dbo].[QueryError]
GO
CREATE TABLE [dbo].[QueryError] (
    [QueryID]          VARCHAR(36)    NOT NULL,
	[Error]            NVARCHAR (MAX) NULL,
    [CreateTime]       DATETIME2 (6)  NULL,
    [LastUpdateTime]   DATETIME2 (6)  NULL
);


DROP TABLE IF EXISTS [dbo].[Statement]
GO
CREATE TABLE [dbo].[Statement] (
    [StatementID]                                   NVARCHAR (36)   NULL,
    [BatchID]                                       NVARCHAR (36)   NULL,
    [ThreadID]                                      NVARCHAR (36)   NULL,
    [IterationID]                                   NVARCHAR (36)   NULL,
    [QueryID]                                       NVARCHAR (36)   NULL,
    [StatementMessage]                              VARCHAR (200)   NULL,
    [DistributedStatementID]                        VARCHAR (36)    NULL,
    [DistributedRequestID]                          VARCHAR (36)    NULL,
    [QueryHash]                                     VARCHAR (36)    NULL,
    [QueryInsightsSessionID]                        INT             NULL,
    [QueryInsightsLoginName]                        NVARCHAR (200)  NULL,
    [QueryInsightsSubmitTime]                       DATETIME2 (6)   NULL,
    [QueryInsightsStartTime]                        DATETIME2 (6)   NULL,
    [QueryInsightsEndTime]                          DATETIME2 (6)   NULL,
    [QueryInsightsDurationInMS]                     INT             NULL,
	[QueryInsightsAllocatedCPUTimeMS]               BIGINT          NULL,
	[QueryInsightsDataScannedRemoteStorageMB]       DECIMAL (18,3)  NULL,
	[QueryInsightsDataScannedMemoryMB]              DECIMAL (18,3)  NULL,
	[QueryInsightsDataScannedDiskMB]                DECIMAL (18,3)  NULL,
    [QueryInsightsRowCount]                         BIGINT          NULL,
    [QueryInsightsStatus]                           VARCHAR (200)   NULL,
    [QueryInsightsResultCacheHit]                   INT             NULL,
    [QueryInsightsLabel]                            VARCHAR (500)   NULL,
    [QueryInsightsCommand]                          VARCHAR (MAX)   NULL,
    [CapacityMetricsStartTime]                      DATETIME2 (6)   NULL,
    [CapacityMetricsEndTime]                        DATETIME2 (6)   NULL,
    [CapacityMetricsCUs]                            DECIMAL (15,4)  NULL,
    [CapacityMetricsQueryPrice]                     DECIMAL (18,6)  NULL,
    [CapacityMetricsDurationInSeconds]              INT             NULL,
    [CreateTime]                                    DATETIME2 (6)   NULL,
    [LastUpdateTime]                                DATETIME2 (6)   NULL
);