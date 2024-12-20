DROP TABLE IF EXISTS [dbo].[LogImport]
GO

CREATE TABLE [dbo].[LogImport] (
    [LogType]        VARCHAR (25) NULL,
    [LogContent]     JSON         NULL
)
GO