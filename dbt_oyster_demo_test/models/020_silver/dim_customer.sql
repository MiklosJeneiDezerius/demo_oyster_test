{{ config(materialized='table', schema='silver') }}

WITH snapshot_source AS (
    SELECT 
        s.*,
        s.dbt_valid_from AS ValidFromTS,
        COALESCE(s.dbt_valid_to, CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6))) AS ValidToTS
    FROM {{ ref('snap_dim_customer') }} s
)
SELECT 
    -- Version-specific compound surrogate key
    CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONCAT(CAST(s.CustomerID AS VARCHAR(50)), '_', CAST(s.ValidFromTS AS VARCHAR(50)))), 2) AS [CustomerSK],
    s.CustomerID,
    TRIM(s.FirstName) AS [FirstName],
    TRIM(s.LastName) AS [LastName],
    UPPER(TRIM(CONCAT(s.FirstName, ' ', s.LastName))) AS [FullName],
    TRIM(s.TaxID) AS [TaxID],
    COALESCE(TRIM(ct.[TypeName]), 'Regular') AS [CustomerType],
    CAST(s.DoB AS DATE) AS [BirthDate],
    s.AddressLine1,
    s.City,
    s.StateRegion,
    s.PostalCode,
    s.Country,
    s.ValidFromTS,
    s.ValidToTS,
    CASE 
        WHEN s.ValidToTS >= CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6)) THEN 1 
        ELSE 0 
    END AS [IsCurrentVersion]
FROM snapshot_source s
LEFT JOIN {{ ref('bronze_customertype') }} ct ON s.CustomerTypeID = ct.CustomerTypeID