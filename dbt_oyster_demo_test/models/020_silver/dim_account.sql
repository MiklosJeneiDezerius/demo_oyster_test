{{ config(materialized='table', schema='silver') }}
SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST([AccountID] AS VARCHAR(50))), 2) AS [AccountSK],
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST([CustomerID] AS VARCHAR(50))), 2) AS [CustomerSK],
    [AccountID], [CustomerID], TRIM([AccountNumber]) AS [AccountNumber], TRIM([AccountType]) AS [AccountType],
    [current_balance] AS [CurrentBalance], TRIM([CurrencyCode]) AS [CurrencyCode], [IngestedTS] AS [ValidFromTS]
FROM {{ ref('bronze_account') }}
