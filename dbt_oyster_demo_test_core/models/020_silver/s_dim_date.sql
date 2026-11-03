{{ config(materialized='table', schema='core_silver') }}

WITH digits AS (
    SELECT 0 AS Digit UNION ALL SELECT 1 UNION ALL SELECT 2
    UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
),
day_offsets AS (
    SELECT
        ones.Digit + 10 * tens.Digit + 100 * hundreds.Digit + 1000 * thousands.Digit AS DayOffset
    FROM digits AS ones
    CROSS JOIN digits AS tens
    CROSS JOIN digits AS hundreds
    CROSS JOIN digits AS thousands
),
date_spine AS (
    SELECT DATEADD(day, DayOffset, CAST('2015-01-01' AS DATE)) AS CalendarDate
    FROM day_offsets
    WHERE DayOffset <= DATEDIFF(day, CAST('2015-01-01' AS DATE), CAST('2035-12-31' AS DATE))
)
SELECT
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
    CASE WHEN DATEPART(weekday, CalendarDate) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    CAST(FORMAT(CalendarDate, 'yyyy-MM') AS VARCHAR(7)) AS YearMonthStr
FROM date_spine