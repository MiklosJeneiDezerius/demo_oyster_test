{{ config(materialized='table', schema='silver') }}

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[AccountID] AS VARCHAR(50))), 2) AS [AccountSK],
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[CustomerID] AS VARCHAR(50))), 2) AS [CustomerSK],
    a.[AccountID],
    a.[CustomerID],
    TRIM(a.[AccountNumber]) AS [AccountNumber],
    COALESCE(TRIM(at.[TypeName]), 'Checking') AS [AccountType],
    a.[Balance] AS [CurrentBalance],
    COALESCE(TRIM(cur.[CurrencyCode]), 'USD') AS [CurrencyCode],
    a.[IngestedTS] AS [ValidFromTS]
FROM {{ ref('bronze_account') }} a
LEFT JOIN {{ ref('bronze_accounttype') }} at 
    ON a.[AccountTypeID] = at.[AccountTypeID]
LEFT JOIN {{ ref('bronze_currency') }} cur 
    ON a.[CurrencyID] = cur.[CurrencyID]
