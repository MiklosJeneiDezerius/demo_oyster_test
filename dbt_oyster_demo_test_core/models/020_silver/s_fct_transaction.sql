SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(t.[transaction_id] AS VARCHAR(50))), 2) AS [s_fct_transaction_sk],
    a.[s_dim_account_sk],
    a.[s_dim_customer_sk],
    CONVERT(INT, CONVERT(CHAR(8), t.[transaction_dttm], 112)) AS [s_dim_date_sk],
    t.[transaction_id],
    t.[account_id],
    t.[transaction_amt],
    t.[transaction_dttm]
FROM {{ ref('b_oys_transaction') }} t
INNER JOIN {{ ref('s_dim_account') }} a
    ON t.[account_id] = a.[account_id]
