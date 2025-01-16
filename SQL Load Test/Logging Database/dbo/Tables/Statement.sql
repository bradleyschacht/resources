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
    [CapacityMetricsCapacityUnitSeconds]            DECIMAL (15,4)  NULL,
    [CapacityMetricsOperationCost]                  DECIMAL (18,6)  NULL,
    [CapacityMetricsDurationInSeconds]              INT             NULL,
    [CreateTime]                                    DATETIME2 (6)   NULL,
    [LastUpdateTime]                                DATETIME2 (6)   NULL
)
GO