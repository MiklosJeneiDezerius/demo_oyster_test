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

-- Isolate unique accounts using historical snapshot grains
active_accounts AS (
    SELECT DISTINCT
        [AccountID]
    FROM {{ ref('dim_account') }}
),

-- Generate the daily cross-join grid matrix footprint
daily_account_spine AS (
    SELECT 
        d.[DateSK],
        d.[FullDate],
        a.[AccountID]
    FROM date_spine d
    CROSS JOIN active_accounts a
),

-- Point-in-time dimension slice tracking references
historical_account_states AS (
    SELECT 
        [AccountSK], [AccountID], [CustomerSK], [ValidFromTS]
    FROM {{ ref('dim_account') }}
),

historical_card_states AS (
    SELECT 
        [AccountSK], [CardSK], [CardTier], [CardStatus], [ValidFromTS], [ValidToTS]
    FROM {{ ref('dim_card') }}
),

-- Roll up daily approved transaction ledger entries
daily_transactions AS (
    SELECT 
        st.[AccountSK],
        CAST(st.[TransactionTimestamp] AS DATE) AS [TransactionDate],
        SUM(st.[Amount]) AS [DailySpendAmount]
    FROM {{ ref('fact_transaction') }} st
    WHERE st.[TransactionStatus] = 'Approved'
    GROUP BY st.[AccountSK], CAST(st.[TransactionTimestamp] AS DATE)
),

-- Resolve point-in-time record status slices and compute windows
rolling_spend_calculation AS (
    SELECT 
        s.[DateSK],
        s.[FullDate],
        s.[AccountID],
        
        -- Map the precise Account and Customer state active on this snapshot date
        da.[AccountSK],
        da.[CustomerSK],
        
        -- Map the precise Card asset state active on this snapshot date
        dc.[CardSK],
        COALESCE(dc.[CardTier], 'Standard') AS [ActualCardTier],
        COALESCE(t.[DailySpendAmount], 0) AS [DailySpendAmount],
        
        -- High-performance continuous 30-day trailing metric engine
        SUM(COALESCE(t.[DailySpendAmount], 0)) OVER (
            PARTITION BY s.[AccountID]
            ORDER BY s.[FullDate]
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS [Rolling30DaySpend]
    FROM daily_account_spine s
    
    INNER JOIN historical_account_states da
        ON s.[AccountID] = da.[AccountID]
        
    LEFT JOIN daily_transactions t 
        ON da.[AccountSK] = t.[AccountSK] 
        AND s.[FullDate] = t.[TransactionDate]
        
    LEFT JOIN historical_card_states dc 
        ON da.[AccountSK] = dc.[AccountSK]
        AND CAST(s.[FullDate] AS DATETIME2) BETWEEN dc.[ValidFromTS] AND dc.[ValidToTS]
)

SELECT
    -- Master compound hash key to isolate daily unique window state rows
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 
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
    
    -- Business logic evaluation rules mapping account status tiers
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 THEN 'Platinum'
        WHEN [Rolling30DaySpend] >= 2000.00 THEN 'Gold'
        ELSE 'Standard'
    END AS [CalculatedSpendingTier],
    
    -- Evaluate tier upgrade eligibility parameters
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] IN ('Standard', 'Gold') THEN 1
        WHEN [Rolling30DaySpend] >= 2000.00 AND [ActualCardTier] = 'Standard' THEN 1
        ELSE 0 
    END AS [IsUpgradeCandidate],
    
    -- Flag risk anomalies (High-tier asset card matching low active spend velocity)
    CASE 
        WHEN [ActualCardTier] = 'Platinum' AND [Rolling30DaySpend] < 5000.00 THEN 1
        WHEN [ActualCardTier] = 'Gold' AND [Rolling30DaySpend] < 2000.00 THEN 1
        ELSE 0 
    END AS [IsLowSpendPremiumAnomaly],
    
    -- Governance lineage alignment tracking evaluations
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] = 'Platinum' THEN 'Aligned'
        WHEN [Rolling30DaySpend] >= 2000.00 AND [Rolling30DaySpend] < 5000.00 AND [ActualCardTier] = 'Gold' THEN 'Aligned'
        WHEN [Rolling30DaySpend] < 2000.00 AND [ActualCardTier] = 'Standard' THEN 'Aligned'
        ELSE 'Misaligned'
    END AS [AlignmentStatusFlag],
    
    CAST(GETDATE() AS DATETIME2(6)) AS [SnapshotMaterializedTS]
FROM rolling_spend_calculation;
