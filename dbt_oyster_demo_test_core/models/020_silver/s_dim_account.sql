SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[account_id] AS VARCHAR(50))), 2) AS [s_dim_account_sk],
    c.[s_dim_customer_sk],
    a.[account_id],
    a.[customer_id],
    a.[balance_amt] AS [current_balance_amt],
    dc.[card_id],
    dc.[card_tier_nm]
FROM {{ ref('b_oys_account') }} a
LEFT JOIN {{ ref('s_dim_customer') }} c
    ON a.[customer_id] = c.[customer_id]
    AND c.[is_current_version_flag] = 1
LEFT JOIN {{ ref('s_dim_card') }} dc
    ON a.[account_id] = dc.[account_id]
    AND dc.[is_current_version_flag] = 1