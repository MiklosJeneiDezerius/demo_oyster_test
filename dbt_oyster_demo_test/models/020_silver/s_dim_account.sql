{{ config(materialized='table', schema='silver') }}

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[AccountID] AS VARCHAR(50))), 2) AS [AccountSK],
    c.[CustomerSK],
    a.[AccountID],
    a.[CustomerID],
    TRIM(a.[AccountNumber]) AS [AccountNumber],
    COALESCE(TRIM(at.[TypeName]), 'Checking') AS [AccountType],
    a.[Balance] AS [CurrentBalance],
    COALESCE(TRIM(cur.[CurrencyCode]), 'USD') AS [CurrencyCode]
FROM {{ ref('b_oys_account') }} a
LEFT JOIN {{ ref('b_oys_account_type') }} at
    ON a.[AccountTypeID] = at.[AccountTypeID]
LEFT JOIN {{ ref('b_oys_currency') }} cur
    ON a.[CurrencyID] = cur.[CurrencyID]
LEFT JOIN {{ ref('s_dim_customer') }} c
    ON a.[CustomerID] = c.[CustomerID]
   AND c.[IsCurrentVersion] = 1
