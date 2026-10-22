{{ config(materialized='table', schema='silver') }}
SELECT
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST([CustomerID] AS VARCHAR(50))), 2) AS [CustomerSK],
    [CustomerID], TRIM([FirstName]) AS [FirstName], TRIM([LastName]) AS [LastName], UPPER(TRIM([Name])) AS [FullName],
    TRIM([TaxID]) AS [TaxID], TRIM([CustomerType]) AS [CustomerType], CAST([DoB] AS DATE) AS [BirthDate], [IngestedTS] AS [ValidFromTS]
FROM {{ ref('bronze_customer') }}
