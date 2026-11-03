{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [AccountSK]
    ,[CustomerSK]
    ,[AccountID]
    ,[CustomerID]
    ,[AccountNumber]
    ,[AccountType]
    ,[CurrentBalance]
    ,[CurrencyCode]
FROM {{ ref('s_dim_account') }}