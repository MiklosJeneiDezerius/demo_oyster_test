{{ config(materialized='table', schema='core_silver') }}

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[AccountID] AS VARCHAR(50))), 2) AS [AccountSK],
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(a.[CustomerID] AS VARCHAR(50))), 2) AS [CustomerSK],
    a.[AccountID],
    a.[CustomerID],
    a.[Balance] AS [CurrentBalance]
FROM {{ ref('b_oys_account') }} a