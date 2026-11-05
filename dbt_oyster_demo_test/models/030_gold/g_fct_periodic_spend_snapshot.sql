{{ config(
    materialized='table',
    schema='gold'
) }}

WITH date_spine AS (
    SELECT DISTINCT 
        [s_dim_date_sk] AS [DateSK],
        [full_dt] AS [FullDate]
    FROM {{ ref('s_dim_date') }}
    -- Original date range through the current day:
    -- WHERE [full_dt] BETWEEN
    -- DATEADD(day, -29, CAST('2025-01-01' AS DATE))
    -- AND CAST(GETDATE() AS DATE)

    -- DEMO ONLY: use a fixed reference date for repeatable 30-day spending.
    WHERE [full_dt] BETWEEN
    DATEADD(day, -29, CAST('{{ var("demo_snapshot_date") }}' AS DATE))
    AND CAST('{{ var("demo_snapshot_date") }}' AS DATE)
),

-- Isolate unique accounts using historical snapshot grains
active_accounts AS (
    SELECT DISTINCT
        [account_id] AS [AccountID]
    FROM {{ ref('s_dim_account') }}
),

-- Generate the daily cross-join grid matrix footprint
daily_account_spine AS (
    SELECT
        d.[DateSK],
        d.[FullDate],
        a.[AccountID],
        DATEADD(
            day,
            1,
            CAST(d.[FullDate] AS DATETIME2(6))
        ) AS [NextDayStartTS]
    FROM date_spine d
    CROSS JOIN active_accounts a
),

-- Point-in-time dimension slice tracking references
accounts AS (
    SELECT
        [s_dim_account_sk] AS [AccountSK],
        [account_id] AS [AccountID],
        [customer_id] AS [CustomerID],
        [s_dim_customer_sk] AS [CustomerSK]
    FROM {{ ref('s_dim_account') }}
),

historical_card_states AS (
    SELECT 
        [s_dim_account_sk] AS [AccountSK],
        [s_dim_card_sk] AS [CardSK],
        [card_tier_nm] AS [CardTier],
        [card_status_cd] AS [CardStatus],
        [valid_from_dttm] AS [ValidFromTS],
        [valid_to_dttm] AS [ValidToTS]
    FROM {{ ref('s_dim_card') }}
),

-- Roll up daily approved transaction ledger entries
daily_transactions AS (
    SELECT 
        st.[s_dim_account_sk] AS [AccountSK],
        CAST(st.[transaction_dttm] AS DATE) AS [TransactionDate],
        SUM(st.[transaction_amt]) AS [DailySpendAmount]
    FROM {{ ref('s_fct_transaction') }} st
    WHERE st.[transaction_status_cd] = 'Approved'
    GROUP BY st.[s_dim_account_sk], CAST(st.[transaction_dttm] AS DATE)
),

-- Resolve point-in-time record status slices and compute windows
rolling_spend_calculation AS (
    SELECT 
        s.[DateSK],
        s.[FullDate],
        s.[AccountID],
        da.[AccountSK],
        cu.[s_dim_customer_sk] AS [CustomerSK],
        dc.[CardSK],
        COALESCE(dc.[CardTier], 'Standard') AS [ActualCardTier],
        COALESCE(t.[DailySpendAmount], 0) AS [DailySpendAmount],
        
        SUM(COALESCE(t.[DailySpendAmount], 0)) OVER (
            PARTITION BY s.[AccountID]
            ORDER BY s.[FullDate]
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS [Rolling30DaySpend]
    FROM daily_account_spine s
    
    INNER JOIN accounts da
        ON s.[AccountID] = da.[AccountID]

    LEFT JOIN {{ ref('s_dim_customer') }} cu
        ON da.[CustomerID] = cu.[customer_id]
        AND cu.[valid_from_dttm] < s.[NextDayStartTS]
        AND cu.[valid_to_dttm] >= s.[NextDayStartTS]
        
    LEFT JOIN daily_transactions t 
        ON da.[AccountSK] = t.[AccountSK] 
        AND s.[FullDate] = t.[TransactionDate]
        
    LEFT JOIN historical_card_states dc
        ON da.[AccountSK] = dc.[AccountSK]
        AND dc.[ValidFromTS] < s.[NextDayStartTS]
        AND dc.[ValidToTS] >= s.[NextDayStartTS]
)

SELECT
    -- Master compound hash key to isolate daily unique window state rows
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 
        CONCAT(CAST([DateSK] AS VARCHAR(20)), '_', CAST([AccountID] AS VARCHAR(50)))
    ), 2) AS [g_fct_periodic_spend_snapshot_sk],
    
    [DateSK] AS [s_dim_date_sk],
    [FullDate] AS [snapshot_dt],
    [AccountSK] AS [s_dim_account_sk],
    [AccountID] AS [account_id],
    [CustomerSK] AS [s_dim_customer_sk],
    [CardSK] AS [s_dim_card_sk],
    [ActualCardTier] AS [actual_card_tier_nm],
    [Rolling30DaySpend] AS [rolling_30_day_spend_amt],
    
    -- Business logic evaluation rules mapping account status tiers
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 THEN 'Platinum'
        WHEN [Rolling30DaySpend] >= 2000.00 THEN 'Gold'
        ELSE 'Standard'
    END AS [calculated_spending_tier_nm],
    
    -- Evaluate tier upgrade eligibility parameters
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] IN ('Standard', 'Gold') THEN 1
        WHEN [Rolling30DaySpend] >= 2000.00 AND [ActualCardTier] = 'Standard' THEN 1
        ELSE 0 
    END AS [is_upgrade_candidate_flag],
    
    -- Flag risk anomalies (High-tier asset card matching low active spend velocity)
    CASE 
        WHEN [ActualCardTier] = 'Platinum' AND [Rolling30DaySpend] < 5000.00 THEN 1
        WHEN [ActualCardTier] = 'Gold' AND [Rolling30DaySpend] < 2000.00 THEN 1
        ELSE 0 
    END AS [is_low_spend_premium_anomaly_flag],
    
    -- Governance lineage alignment tracking evaluations
    CASE 
        WHEN [Rolling30DaySpend] >= 5000.00 AND [ActualCardTier] = 'Platinum' THEN 'Aligned'
        WHEN [Rolling30DaySpend] >= 2000.00 AND [Rolling30DaySpend] < 5000.00 AND [ActualCardTier] = 'Gold' THEN 'Aligned'
        WHEN [Rolling30DaySpend] < 2000.00 AND [ActualCardTier] = 'Standard' THEN 'Aligned'
        ELSE 'Misaligned'
    END AS [alignment_status_cd],
    
    CAST(GETDATE() AS DATETIME2(6)) AS [snapshot_materialized_dttm]
FROM rolling_spend_calculation
-- Original output: all daily snapshots from 2025-01-01.
-- WHERE [FullDate] >= CAST('2025-01-01' AS DATE);
-- DEMO ONLY: return just the fixed reference day's snapshot.
WHERE [FullDate] = CAST('{{ var("demo_snapshot_date") }}' AS DATE);
