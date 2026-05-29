DROP TABLE IF EXISTS dbo.DimDate
GO

DECLARE @StartDate  DATE = '2020-01-01'
DECLARE @EndDate    DATE = '2021-12-31'

/*******************************************************************************************************************************************************/

CREATE TABLE dbo.DimDate
    (
        [DateKey]               [INT]           NOT NULL,
        [Date]                  [DATE]          NOT NULL,
        [StandardDate]          [CHAR](10)      NOT NULL,
        [Day]                   [SMALLINT]      NOT NULL,
        [DayNumber]             [VARCHAR](7)    NOT NULL, /*[CHAR](2) without unknown member*/
        [DayName]               [VARCHAR](7)    NOT NULL, /*[VARCHAR](4) without unknown member*/
        [DayOfWeek]             [SMALLINT]      NOT NULL,
        [DayOfWeekName]         [VARCHAR](9)    NOT NULL,
        [DayOfWeekShortName]    [VARCHAR](7)    NOT NULL, /*[CHAR](3) without unknown member*/
        [DayOfWeekInMonth]      [SMALLINT]      NOT NULL,
        [DayOfYear]             [SMALLINT]      NOT NULL,
        [WeekOfMonth]           [SMALLINT]      NOT NULL,
        [WeekOfYear]            [SMALLINT]      NOT NULL,
        [Month]                 [SMALLINT]      NOT NULL,
        [MonthNumber]           [VARCHAR](7)    NOT NULL, /*[CHAR](2) without unknown member*/
        [MonthName]             [VARCHAR](9)    NOT NULL,
        [MonthShortName]        [VARCHAR](7)    NOT NULL, /*[CHAR](3) without unknown member*/
        [Quarter]               [SMALLINT]      NOT NULL,
        [QuarterName]           [VARCHAR](7)    NOT NULL,
        [QuarterShortName]      [VARCHAR](7)    NOT NULL, /*[CHAR](3) without unknown member*/
        [Year]                  [SMALLINT]      NOT NULL,
        [YearName]              [VARCHAR](7)    NOT NULL, /*[CHAR](6) without unknown member*/
        [MonthYear]             [CHAR](10)      NOT NULL,
        [MMYYYY]                [VARCHAR](7)    NOT NULL, /*[CHAR](6) without unknown member*/
        [FirstDayOfMonth]       [DATE]          NOT NULL,
        [LastDayOfMonth]        [DATE]          NOT NULL,
        [FirstDayOfQuarter]     [DATE]          NOT NULL,
        [LastDayOfQuarter]      [DATE]          NOT NULL,
        [FirstDayOfYear]        [DATE]          NOT NULL,
        [LastDayOfYear]         [DATE]          NOT NULL
    )

INSERT INTO dbo.DimDate VALUES(19000101, '1900-01-01', '01/01/1900', 0, 'Unknown', 'Unknown', 0, 'Unknown', 'Unknown', 0, 0, 0, 0, 0, 'Unknown', 'Unknown', 'Unknown', 0, 'Unknown', 'Unknown', 1900, 'Unknown', 'Unknown', 'Unknown', '1900-01-01', '1900-01-01', '1900-01-01', '1900-01-01', '1900-01-01', '1900-01-01')

INSERT INTO dbo.DimDate
SELECT
    /*  Date  */
    CONVERT(VARCHAR, CurrentDate, 112) AS DateKey,
    CurrentDate AS [Date],
    FORMAT(CurrentDate, 'MM/dd/yyyy') AS StandardDate,
    
    /*  Day  */
    DATEPART(DAY, CurrentDate) AS [Day],
    FORMAT(CurrentDate, 'dd') AS DayNumber,
    CASE 
        WHEN DATEPART(DAY, CurrentDate) IN (1, 21, 31) THEN CONVERT(VARCHAR(2), DATEPART(DAY, CurrentDate)) + 'st'
        WHEN DATEPART(DAY, CurrentDate) IN (2, 22)     THEN CONVERT(VARCHAR(2), DATEPART(DAY, CurrentDate)) + 'nd'
        WHEN DATEPART(DAY, CurrentDate) IN (3, 23)     THEN CONVERT(VARCHAR(2), DATEPART(DAY, CurrentDate)) + 'rd'
        ELSE                                                CONVERT(VARCHAR(2), DATEPART(DAY, CurrentDate)) + 'th'
        END AS DayName,
    DATEPART(WEEKDAY, CurrentDate) AS DayOfWeek,
    FORMAT(CurrentDate, 'dddd') AS DayOfWeekName,
    FORMAT(CurrentDate, 'ddd') AS DayOfWeekShortName,
    (DATEPART(DAY, CurrentDate) + 6) / 7 AS DayOfWeekInMonth,
    DATEPART(DAYOFYEAR, CurrentDate) AS DayOfYear,
    
    /*  Week  */
    DATEPART(WEEK, CurrentDate) + 1 - DATEPART(WEEK, CAST(DATEPART(MONTH, CurrentDate) AS VARCHAR) + '/1/' + CAST(DATEPART(YEAR, CurrentDate) AS VARCHAR)) AS WeekOfMonth,
    DATEPART(WEEK, CurrentDate) AS WeekOfYear,

    /*  Month  */
    DATEPART(MONTH, CurrentDate) AS [Month],
    FORMAT(CurrentDate, 'MM') AS MonthNumber,
    FORMAT(CurrentDate, 'MMMM') AS MonthName,
    FORMAT(CurrentDate, 'MMM') AS MonthShortName,

    /*  Quarter  */
    DATEPART(QUARTER, CurrentDate) AS [Quarter],
    CASE DATEPART(QUARTER, CurrentDate) 
        WHEN 1 THEN 'First'
        WHEN 2 THEN 'Second'
        WHEN 3 THEN 'Third'
        WHEN 4 THEN 'Fourth'
        END AS QuarterName,
    CASE DATEPART(QUARTER, CurrentDate) 
        WHEN 1 THEN '1st'
        WHEN 2 THEN '2nd'
        WHEN 3 THEN '3rd'
        WHEN 4 THEN '4th'
        END AS QuarterShortName,
    
    /*  Year  */
    DATEPART(YEAR, CurrentDate) AS [Year],
    'CY' + FORMAT(CurrentDate, 'yyyy') AS YearName,
    FORMAT(CurrentDate, 'MMM-yyyy') AS MonthYear,
    FORMAT(CurrentDate, 'MMyyyy') AS MMYYYY,

    /*  Period Begin and End Dates  */
    DATETRUNC(MONTH, CurrentDate) AS FirstDayOfMonth,
    EOMONTH(CurrentDate) AS LastDayOfMonth,
    DATETRUNC(QUARTER, CurrentDate) AS FirstDayOfQuarter,
    EOMONTH(DATEFROMPARTS(YEAR(CurrentDate), 3 * DATEPART(QUARTER, CurrentDate), 1)) AS LastDayOfQuarter,
    DATETRUNC(YEAR, CurrentDate) AS FirstDayOfYear,
    DATEFROMPARTS(YEAR(CurrentDate), 12, 31) AS LastDayOfYear
FROM
    (
        SELECT
            DATEADD(DAY, value, @StartDate) AS CurrentDate
        FROM GENERATE_SERIES(0, DATEDIFF(DAY, @StartDate, @EndDate), 1)
    ) AS dates

SELECT
    *
FROM dbo.DimDate
ORDER BY DateKey