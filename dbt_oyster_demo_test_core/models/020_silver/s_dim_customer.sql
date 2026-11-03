{{ config(materialized='table', schema='core_silver') }}

SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(c.[CustomerID] AS VARCHAR(50))), 2) AS [CustomerSK],
    c.[CustomerID],
    c.[FirstName],
    c.[LastName]
FROM {{ ref('b_oys_customer') }} c