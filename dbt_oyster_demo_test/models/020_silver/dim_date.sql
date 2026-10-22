{{ config(
    materialized='table',
    schema='silver'
) }}

WITH Digits AS (
    SELECT 0 AS Digit UNION ALL SELECT 1 UNION ALL SELECT 2
    UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9
),
DayOffsets AS (
    SELECT
        ones.Digit + 10 * tens.Digit + 100 * hundreds.Digit
            + 1000 * thousands.Digit AS DayOffset
    FROM Digits AS ones
    CROSS JOIN Digits AS tens
    CROSS JOIN Digits AS hundreds
    CROSS JOIN Digits AS thousands
),
DateSpine AS (
    SELECT
        DATEADD(day, DayOffset, CAST('2015-01-01' AS DATE)) AS CalendarDate
    FROM DayOffsets
    WHERE DayOffset <= DATEDIFF(day, CAST('2015-01-01' AS DATE), CAST('2035-12-31' AS DATE))
)

SELECT
    -- Surrogate Key: Smart Date Key format (YYYYMMDD) as an integer
    CAST(FORMAT(CalendarDate, 'yyyyMMdd') AS INT) AS DateSK,
    
    CalendarDate AS FullDate,
    DATEPART(year, CalendarDate) AS CalendarYear,
    DATEPART(quarter, CalendarDate) AS CalendarQuarter,
    CONCAT('Q', DATEPART(quarter, CalendarDate)) AS CalendarQuarterName,
    DATEPART(month, CalendarDate) AS MonthNumberOfYear,
    CAST(FORMAT(CalendarDate, 'MMMM') AS VARCHAR(50)) AS MonthName,
    CAST(FORMAT(CalendarDate, 'MMM') AS VARCHAR(50)) AS MonthShortName,
    DATEPART(week, CalendarDate) AS WeekNumberOfYear,
    DATEPART(day, CalendarDate) AS DayNumberOfMonth,
    DATEPART(dayofyear, CalendarDate) AS DayNumberOfYear,
    DATEPART(weekday, CalendarDate) AS DayNumberOfWeek,
    CAST(FORMAT(CalendarDate, 'dddd') AS VARCHAR(50)) AS DayName,
    CAST(FORMAT(CalendarDate, 'ddd') AS VARCHAR(50)) AS DayShortName,
    
    -- Business Flags
    CASE 
        WHEN DATEPART(weekday, CalendarDate) IN (1, 7) THEN 1 
        ELSE 0 
    END AS IsWeekend,
    
    -- Year-Month string identifier (YYYY-MM)
    CAST(FORMAT(CalendarDate, 'yyyy-MM') AS VARCHAR(7)) AS YearMonthStr

FROM DateSpine
