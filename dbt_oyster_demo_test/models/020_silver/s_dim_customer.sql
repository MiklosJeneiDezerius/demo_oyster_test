{{ config(materialized='table', schema='silver') }}

WITH snapshot_records AS (
    SELECT
        c.[CustomerID],
        c.[TaxID],
        c.[CustomerTypeID],
        TRIM(c.[FirstName]) AS [FirstName],
        TRIM(c.[LastName]) AS [LastName],
        CAST(c.[DoB] AS DATE) AS [BirthDate],
        COALESCE(c.[AddressLine1], 'NOT PROVIDED') AS [AddressLine1],
        COALESCE(c.[City], 'NOT PROVIDED') AS [City],
        COALESCE(c.[StateRegion], 'NOT PROVIDED') AS [StateRegion],
        COALESCE(c.[PostalCode], 'NOT PROVIDED') AS [PostalCode],
        COALESCE(c.[Country], 'NOT PROVIDED') AS [Country],
        CAST(c.[m_valid_from_dttm] AS DATETIME2(6)) AS [SnapshotValidFromTS],
        COALESCE(
            CAST(c.[m_valid_to_dttm] AS DATETIME2(6)),
            CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6))
        ) AS [ValidToTS],
        ROW_NUMBER() OVER (
            PARTITION BY c.[CustomerID]
            ORDER BY c.[m_valid_from_dttm] ASC
        ) AS [VersionNumber]
    FROM {{ ref('ldh_oys_customer') }} c
),
customer_versions AS (
    SELECT
        s.[CustomerID],
        s.[TaxID],
        s.[CustomerTypeID],
        s.[FirstName],
        s.[LastName],
        s.[BirthDate],
        s.[AddressLine1],
        s.[City],
        s.[StateRegion],
        s.[PostalCode],
        s.[Country],
        COALESCE(NULLIF(TRIM(t.[TypeName]), ''), 'Individual') AS [CustomerType],
        CASE
            WHEN s.[VersionNumber] = 1 THEN CAST('1900-01-01 00:00:00.000000' AS DATETIME2(6))
            ELSE s.[SnapshotValidFromTS]
        END AS [ValidFromTS],
        s.[ValidToTS]
    FROM snapshot_records s
    LEFT JOIN {{ ref('b_oys_customer_type') }} t
        ON s.[CustomerTypeID] = t.[CustomerTypeID]
)
SELECT
    CONVERT(
        VARCHAR(64),
        HASHBYTES(
            'SHA2_256',
            CONCAT(CAST([CustomerID] AS VARCHAR(50)), '|', CONVERT(VARCHAR(50), [ValidFromTS], 121))
        ),
        2
    ) AS [CustomerSK],
    [CustomerID],
    [FirstName],
    [LastName],
    CONCAT([FirstName], ' ', [LastName]) AS [FullName],
    [TaxID],
    [CustomerType],
    [BirthDate],
    [AddressLine1],
    [City],
    [StateRegion],
    [PostalCode],
    [Country],
    [ValidFromTS],
    [ValidToTS],
    CASE
        WHEN [ValidToTS] >= CAST('9999-12-31 00:00:00.000000' AS DATETIME2(6)) THEN 1
        ELSE 0
    END AS [IsCurrentVersion]
FROM customer_versions
