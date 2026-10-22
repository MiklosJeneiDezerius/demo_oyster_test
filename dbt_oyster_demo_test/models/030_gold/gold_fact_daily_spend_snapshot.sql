{{ config(
    materialized='table',
    schema='gold'
) }}

WITH date_spine AS (
    SELECT DISTINCT 
        [DateSK],
        [FullDate]
    FROM {{ ref('dim_date') }}
    WHERE [FullDate] BETWEEN '2025-01-01' AND CAST(GETDATE() AS DATE)
),

active_accounts AS (
    SELECT 
        [AccountSK],
        [AccountID],
        [CustomerSK]
    FROM {{ ref('dim_account') }}
),

daily_account_spine AS (
    SELECT 
        d.[DateSK],
        d.[FullDate],
        a.[AccountSK],
        a.[AccountID],
        a.[CustomerSK]
    FROM date_spine d
    CROSS JOIN active_accounts a
),

historical_card_states AS (
    SELECT 
        [AccountSK],
        [CardSK],
        [CardTier],
        [CardStatus],
        [ValidFromTS],
        [ValidToTS]
    FROM {{ ref('dim_card') }}
),

daily_transactions AS (
    SELECT 
        [AccountSK],
        CAST([TransactionTimestamp] AS DATE) AS [TransactionDate],
        SUM([Amount]) AS [DailySpendAmount]
    FROM {{ ref('fact_transaction') }}
    WHERE [TransactionStatus] = 'Approved'
    GROUP BY [AccountSK], CAST([TransactionTimestamp] AS DATE)
),

rolling_spend_calculation AS (
    SELECT 
        s.[DateSK],
        s.[FullDate],
        s.[AccountSK],
        s.[AccountID],
        s.[CustomerSK],
        c.[CardSK],
        COALESCE(c.[CardTier], 'Standard') AS [ActualCardTier],
        COALESCE(t.[DailySpendAmount], 0) AS [DailySpendAmount],
        SUM(COALESCE(t.[DailySpendAmount], 0)) OVER (
            PARTITION BY s.[AccountSK]
            ORDER BY s.[FullDate]
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS [Rolling30DaySpend]
    FROM daily_account_spine s
    LEFT JOIN daily_transactions t 
        ON s.[AccountSK] = t.[AccountSK] 
        AND s.[FullDate] = t.[TransactionDate]
    LEFT JOIN historical_card_states c 
        ON s.[AccountSK] = c.[AccountSK]
        AND s.[FullDate] BETWEEN CAST(c.[ValidFromTS] AS DATE) AND CAST(c.[ValidToTS] AS DATE)
)

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 
        CONCAT([DateSK], '_', [AccountID])
    ), 2) AS [SpendSnapshotSK],
    
    [DateSK],
    [FullDate] AS [SnapshotDate],
    [AccountSK],
    [AccountID],
    [CustomerSK],
    [CardSK],
    [ActualCardTier],
    [Rolling30DaySpend],
    
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 THEN 'Platinum'
        WHEN [Rolling30DaySpend] >= 2000.00 THEN 'Gold'
        ELSE 'Standard'
    END AS [CalculatedSpendingTier],
    
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] IN ('Standard', 'Gold') THEN 1
        WHEN [Rolling30DaySpend] >= 2000.00 AND [ActualCardTier] = 'Standard' THEN 1
        ELSE 0 
    END AS [IsUpgradeCandidate],
    
    CASE 
        WHEN [ActualCardTier] = 'Platinum' AND [Rolling30DaySpend] < 5000.00 THEN 1
        WHEN [ActualCardTier] = 'Gold' AND [Rolling30DaySpend] < 2000.00 THEN 1
        ELSE 0 
    END AS [IsLowSpendPremiumAnomaly],
    
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] = 'Platinum' THEN 'Aligned'
        WHEN [Rolling30DaySpend] >= 2000.00 AND [Rolling30DaySpend] < 5000.00 AND [ActualCardTier] = 'Gold' THEN 'Aligned'
        WHEN [Rolling30DaySpend] < 2000.00 AND [ActualCardTier] = 'Standard' THEN 'Aligned'
        ELSE 'Misaligned'
    END AS [AlignmentStatusFlag],
    
    CAST(GETDATE() AS DATETIME2(6)) AS [SnapshotMaterializedTS]
FROM rolling_spend_calculation;
