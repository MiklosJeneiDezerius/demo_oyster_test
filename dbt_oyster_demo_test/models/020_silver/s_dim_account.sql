{{ config(materialized='table', schema='silver') }}

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[account_id] AS VARCHAR(50))), 2) AS [s_dim_account_sk],
    c.[s_dim_customer_sk],
    a.[account_id],
    a.[customer_id],
    TRIM(a.[account_number_txt]) AS [account_number_txt],
    COALESCE(TRIM(at.[type_nm]), 'Checking') AS [account_type_nm],
    a.[balance_amt] AS [current_balance_amt],
    COALESCE(TRIM(cur.[currency_cd]), 'USD') AS [currency_cd]
FROM {{ ref('b_oys_account') }} a
LEFT JOIN {{ ref('b_oys_account_type') }} at
    ON a.[account_type_id] = at.[account_type_id]
LEFT JOIN {{ ref('b_oys_currency') }} cur
    ON a.[currency_id] = cur.[currency_id]
LEFT JOIN {{ ref('s_dim_customer') }} c
    ON a.[customer_id] = c.[customer_id]
   AND c.[is_current_version_flag] = 1
