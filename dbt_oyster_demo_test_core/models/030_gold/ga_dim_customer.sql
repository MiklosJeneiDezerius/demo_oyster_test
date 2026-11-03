{{ config(materialized='table', schema='core_gold') }}

SELECT
    [CustomerSK],
    [CustomerID],
    [FirstName],
    [LastName],
    CONCAT([FirstName], ' ', [LastName]) AS [FullName]
FROM {{ ref('s_dim_customer') }}