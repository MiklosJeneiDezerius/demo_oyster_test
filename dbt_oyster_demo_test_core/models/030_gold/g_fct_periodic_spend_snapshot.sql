{{ config(materialized='table', schema='core_gold') }}

WITH date_spine AS (
    SELECT [DateSK], [FullDate]
    FROM {{ ref('g_dim_date') }}
    WHERE [FullDate] BETWEEN CAST('2024-12-03' AS DATE) AND CAST(GETDATE() AS DATE)
),
active_accounts AS (
    SELECT [AccountSK], [CustomerSK], [AccountID]
    FROM {{ ref('ga_dim_account') }}
),
daily_account_spine AS (
    SELECT d.[DateSK], d.[FullDate], a.[AccountSK], a.[CustomerSK], a.[AccountID]
    FROM date_spine d
    CROSS JOIN active_accounts a
),
daily_transactions AS (
    SELECT
        t.[AccountID],
        CAST(t.[TransactionTimestamp] AS DATE) AS [TransactionDate],
        SUM(t.[Amount]) AS [DailySpendAmount]
    FROM {{ ref('s_fct_transaction') }} t
    GROUP BY t.[AccountID], CAST(t.[TransactionTimestamp] AS DATE)
),
ranked_cards AS (
    SELECT
        c.[AccountID],
        c.[CardSK],
        c.[CardTier],
        ROW_NUMBER() OVER (
            PARTITION BY c.[AccountID]
            ORDER BY c.[CardID] DESC
        ) AS [CardRank]
    FROM {{ ref('ga_dim_card') }} c
),
rolling_spend_calculation AS (
    SELECT
        s.[DateSK],
        s.[FullDate],
        s.[AccountSK],
        s.[CustomerSK],
        s.[AccountID],
        c.[CardSK],
        COALESCE(c.[CardTier], 'Standard') AS [ActualCardTier],
        COALESCE(t.[DailySpendAmount], CAST(0 AS DECIMAL(18, 4))) AS [DailySpendAmount],
        SUM(COALESCE(t.[DailySpendAmount], CAST(0 AS DECIMAL(18, 4)))) OVER (
            PARTITION BY s.[AccountID]
            ORDER BY s.[FullDate]
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS [Rolling30DaySpend]
    FROM daily_account_spine s
    LEFT JOIN daily_transactions t
        ON s.[AccountID] = t.[AccountID]
       AND s.[FullDate] = t.[TransactionDate]
    LEFT JOIN ranked_cards c
        ON s.[AccountID] = c.[AccountID]
       AND c.[CardRank] = 1
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES(
        'SHA2_256',
        CONCAT(CAST([DateSK] AS VARCHAR(20)), '_', CAST([AccountID] AS VARCHAR(50)))
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
        WHEN [Rolling30DaySpend] >= 5000.00
             AND [ActualCardTier] IN ('Standard', 'Gold') THEN 1
        WHEN [Rolling30DaySpend] >= 2000.00
             AND [ActualCardTier] = 'Standard' THEN 1
        ELSE 0
    END AS [IsUpgradeCandidate],
    CASE
        WHEN [ActualCardTier] = 'Platinum' AND [Rolling30DaySpend] < 5000.00 THEN 1
        WHEN [ActualCardTier] = 'Gold' AND [Rolling30DaySpend] < 2000.00 THEN 1
        ELSE 0
    END AS [IsLowSpendPremiumAnomaly],
    CASE
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] = 'Platinum' THEN 'Aligned'
        WHEN [Rolling30DaySpend] >= 2000.00
             AND [Rolling30DaySpend] < 5000.00
             AND [ActualCardTier] = 'Gold' THEN 'Aligned'
        WHEN [Rolling30DaySpend] < 2000.00 AND [ActualCardTier] = 'Standard' THEN 'Aligned'
        ELSE 'Misaligned'
    END AS [AlignmentStatusFlag],
    CAST(GETDATE() AS DATETIME2(6)) AS [SnapshotMaterializedTS]
FROM rolling_spend_calculation
WHERE [FullDate] >= CAST('2025-01-01' AS DATE)