CREATE TABLE [oystr_silver].[dim_date] (
    [DateSK]              INT          NULL,
    [FullDate]            DATE         NULL,
    [CalendarYear]        INT          NULL,
    [CalendarQuarter]     INT          NULL,
    [CalendarQuarterName] VARCHAR (13) NOT NULL,
    [MonthNumberOfYear]   INT          NULL,
    [MonthName]           VARCHAR (50) NULL,
    [MonthShortName]      VARCHAR (50) NULL,
    [WeekNumberOfYear]    INT          NULL,
    [DayNumberOfMonth]    INT          NULL,
    [DayNumberOfYear]     INT          NULL,
    [DayNumberOfWeek]     INT          NULL,
    [DayName]             VARCHAR (50) NULL,
    [DayShortName]        VARCHAR (50) NULL,
    [IsWeekend]           INT          NOT NULL,
    [YearMonthStr]        VARCHAR (7)  NULL
);


GO