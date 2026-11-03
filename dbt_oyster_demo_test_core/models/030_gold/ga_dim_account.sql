{{ config(materialized='table', schema='core_gold') }}

SELECT
    a.[AccountSK],
    a.[AccountID],
    a.[CustomerSK],
    a.[CustomerID],
    c.[FirstName],
    c.[LastName],
    CONCAT(c.[FirstName], ' ', c.[LastName]) AS [FullName],
    a.[CurrentBalance]
FROM {{ ref('s_dim_account') }} a
LEFT JOIN {{ ref('s_dim_customer') }} c
    ON a.[CustomerSK] = c.[CustomerSK]