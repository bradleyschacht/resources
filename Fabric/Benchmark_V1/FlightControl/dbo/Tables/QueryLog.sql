CREATE TABLE [dbo].[QueryLog] (
    [QueryLogID]                       INT             IDENTITY (1, 1) NOT NULL,
    [ScenarioID]                       INT             NULL,
    [BatchID]                          INT             NULL,
    [ThreadID]                         INT             NULL,
    [IterationID]                      INT             NULL,
    [QueryID]                          INT             NULL,
    [QueryMessage]                     VARCHAR (200)   NULL,
    [DistributedStatementID]           VARCHAR (36)    NULL,
    [DistributedRequestID]             VARCHAR (36)    NULL,
    [QueryHash]                        VARCHAR (36)    NULL,
    [QueryInsightsSessionID]           INT             NULL,
    [QueryInsightsLoginName]           NVARCHAR (200)  NULL,
    [QueryInsightsSubmitTime]          DATETIME2 (6)   NULL,
    [QueryInsightsStartTime]           DATETIME2 (6)   NULL,
    [QueryInsightsEndTime]             DATETIME2 (6)   NULL,
    [QueryInsightsDurationInMS]        INT             NULL,
    [QueryInsightsRowCount]            BIGINT          NULL,
    [QueryInsightsStatus]              VARCHAR (200)   NULL,
    [QueryInsightsResultCacheHit]      INT             NULL,
    [QueryInsightsLabel]               VARCHAR (500)   NULL,
    [QueryInsightsQueryText]           VARCHAR (MAX)   NULL,
    [CapacityMetricsStartTime]         DATETIME2 (6)   NULL,
    [CapacityMetricsEndTime]           DATETIME2 (6)   NULL,
    [CapacityMetricsCUs]               DECIMAL (15, 4) NULL,
    [CapacityMetricsQueryPrice]        DECIMAL (18, 6) NULL,
    [CapacityMetricsDurationInSeconds] INT             NULL,
    [CreateTime]                       DATETIME2 (6)   NULL,
    [LastUpdateTime]                   DATETIME2 (6)   NULL
);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_QueryLog_ScenarioID]
    ON [dbo].[QueryLog]([ScenarioID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_QueryLog_BatchID]
    ON [dbo].[QueryLog]([BatchID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_QueryLog_ThreadID]
    ON [dbo].[QueryLog]([ThreadID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_QueryLog_IterationID]
    ON [dbo].[QueryLog]([IterationID] ASC);
GO

CREATE NONCLUSTERED INDEX [nci_dbo_QueryLog_QueryID]
    ON [dbo].[QueryLog]([QueryID] ASC);
GO

CREATE CLUSTERED INDEX [ci_dbo_QueryLog_QueryLogID]
    ON [dbo].[QueryLog]([QueryLogID] ASC);
GO