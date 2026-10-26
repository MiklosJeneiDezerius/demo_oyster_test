{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [DateSK]
    ,[FullDate]
    ,[CalendarYear]
    ,[CalendarQuarter]
    ,[CalendarQuarterName]
    ,[MonthNumberOfYear]
    ,[MonthName]
    ,[MonthShortName]
    ,[WeekNumberOfYear]
    ,[DayNumberOfMonth]
    ,[DayNumberOfYear]
    ,[DayNumberOfWeek]
    ,[DayName]
    ,[DayShortName]
    ,[IsWeekend]
    ,[YearMonthStr]
FROM {{ ref('dim_date') }}