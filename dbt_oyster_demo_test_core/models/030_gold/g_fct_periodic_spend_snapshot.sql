WITH date_spine AS (
    SELECT [s_dim_date_sk], [full_dt]
    FROM {{ ref('s_dim_date') }}
    WHERE [full_dt] BETWEEN
        DATEADD(day, -29, CAST('2025-01-01' AS DATE))
        AND CAST(GETDATE() AS DATE)
),
daily_transactions AS (
    SELECT
        [s_dim_account_sk],
        CAST([transaction_dttm] AS DATE) AS [transaction_dt],
        SUM([transaction_amt]) AS [daily_spend_amt]
    FROM {{ ref('s_fct_transaction') }}
    GROUP BY [s_dim_account_sk], CAST([transaction_dttm] AS DATE)
),
accounts AS (
    SELECT
        [s_dim_account_sk],
        [s_dim_customer_sk],
        [account_id],
        [card_id],
        COALESCE(NULLIF(TRIM([card_tier_nm]), ''), 'Standard') AS [actual_card_tier_nm]
    FROM {{ ref('s_dim_account') }}
),
rolling_spend AS (
    SELECT
        d.[s_dim_date_sk],
        d.[full_dt],
        a.[s_dim_account_sk],
        a.[s_dim_customer_sk],
        a.[account_id],
        a.[card_id],
        a.[actual_card_tier_nm],
        SUM(COALESCE(t.[daily_spend_amt], 0)) OVER (
            PARTITION BY a.[account_id]
            ORDER BY d.[full_dt]
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS [rolling_30_day_spend_amt]
    FROM date_spine d
    CROSS JOIN accounts a
    LEFT JOIN daily_transactions t
        ON a.[s_dim_account_sk] = t.[s_dim_account_sk]
       AND d.[full_dt] = t.[transaction_dt]
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
        CONCAT(CAST([s_dim_date_sk] AS VARCHAR(20)), '_', CAST([account_id] AS VARCHAR(50)))
    ), 2) AS [g_fct_periodic_spend_snapshot_sk],
    [s_dim_date_sk],
    [full_dt] AS [snapshot_dt],
    [s_dim_account_sk],
    [s_dim_customer_sk],
    [account_id],
    [card_id],
    [actual_card_tier_nm],
    [rolling_30_day_spend_amt],
    CASE
        WHEN [rolling_30_day_spend_amt] >= 5000.00 THEN 'Platinum'
        WHEN [rolling_30_day_spend_amt] >= 2000.00 THEN 'Gold'
        ELSE 'Standard'
    END AS [calculated_spending_tier_nm],
        CASE
           WHEN [rolling_30_day_spend_amt] >= 5000.00
               AND [actual_card_tier_nm] IN ('Standard', 'Gold') THEN 1
           WHEN [rolling_30_day_spend_amt] >= 2000.00
               AND [actual_card_tier_nm] = 'Standard' THEN 1
           ELSE 0
        END AS [is_upgrade_candidate_flag],
        CASE
           WHEN [actual_card_tier_nm] = 'Platinum'
               AND [rolling_30_day_spend_amt] < 5000.00 THEN 1
           WHEN [actual_card_tier_nm] = 'Gold'
               AND [rolling_30_day_spend_amt] < 2000.00 THEN 1
           ELSE 0
        END AS [is_low_spend_premium_anomaly_flag],
        CASE
           WHEN [rolling_30_day_spend_amt] >= 5000.00
               AND [actual_card_tier_nm] = 'Platinum' THEN 'Aligned'
           WHEN [rolling_30_day_spend_amt] >= 2000.00
               AND [rolling_30_day_spend_amt] < 5000.00
               AND [actual_card_tier_nm] = 'Gold' THEN 'Aligned'
           WHEN [rolling_30_day_spend_amt] < 2000.00
               AND [actual_card_tier_nm] = 'Standard' THEN 'Aligned'
           ELSE 'Misaligned'
        END AS [alignment_status_cd],
    CAST(GETDATE() AS DATETIME2(6)) AS [snapshot_materialized_dttm]
FROM rolling_spend
WHERE [full_dt] >= CAST('2025-01-01' AS DATE)
