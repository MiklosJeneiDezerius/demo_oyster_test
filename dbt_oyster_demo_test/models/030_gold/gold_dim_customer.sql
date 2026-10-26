{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT
    [CustomerSK]
    ,[CustomerID]
    ,[FirstName]
    ,[LastName]
    ,[FullName]
    ,[TaxID] -- Automatically masked at the Warehouse layer via your DDM policy
    ,[CustomerType]
    ,[BirthDate]
    ,[AddressLine1]
    ,[City]
    ,[StateRegion]
    ,[PostalCode]
    ,[Country]
    ,[ValidFromTS]
    ,[ValidToTS]
FROM {{ ref('dim_customer') }}
WHERE [IsCurrentVersion] = 1 -- Filters down to the single active operational truth